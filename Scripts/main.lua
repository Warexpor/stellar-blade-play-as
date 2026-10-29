-- StellarBladePlayAs: play as Tachy, Raven or Scarlet. Eve wears the other's body, face or hair and blade (looks.lua) and
-- speaks with her voice (voice.lua); everything else stays Eve's: her moves, skills, physics, and any other mod's work
-- on her body. A mod of its own: it needs nothing else, and the Stellar Blade Gore mod (if there) sees who she looks
-- like by her meshes for its own death sounds.
--   F4        the in-game picker (menu.lua; on the controller settings.menuPad): pick, Apply. Its one key
-- All of it runs from Eve's own ReceiveTick (on the game thread). The menu's text is set by StellarBladePlayAs's own DLL
-- (StellarBladePlayAsText, native/playas.c).
local VERSION = "0.2.1"
local DIR = "ue4ss/Mods/StellarBladePlayAs/"
local SCRIPTS = DIR .. "Scripts/"
local CHOICE, LOG = DIR .. "choice.txt", DIR .. "stellarbladeplayas.log"
-- its folder before it was renamed (SBPlayAs): its pick is read once if this one has none
local OLD = "ue4ss/Mods/SBPlayAs/"
local TICK_FN = "/Game/Art/Character/PC/CH_P_EVE_01/Blueprints/CH_P_EVE_01_Blueprint.CH_P_EVE_01_Blueprint_C:ReceiveTick"
local LABELS = { eve = "Eve", tachy = "Tachy", raven = "Raven", scarlet = "Scarlet" }

local lg = io.open(LOG, "w")
local function log(s)
  local line = string.format("[%s] %s\n", os.date("%H:%M:%S"), s)
  if lg then lg:write(line); lg:flush() end
  print("[StellarBladePlayAs] " .. s .. "\n")
end
-- an error that comes back each frame: logged the first time, then at most every ERR_S s with how often it came (a line
-- each frame, flushed and printed to UE4SS's console, would itself stutter the game)
local ERR_S, errs = 10, {}
local function logerr(what, err)
  local k = what .. tostring(err)
  local e = errs[k]
  local now = os.clock()
  if not e then errs[k] = { n = 0, at = now }; log(what .. ": " .. tostring(err)); return end
  e.n = e.n + 1
  if now - e.at >= ERR_S then
    log(string.format("%s: %s (%d more times in %.0f s)", what, tostring(err), e.n, now - e.at))
    e.n, e.at = 0, now
  end
end
local function try(f) local ok, r = pcall(f); if ok then return r end end
local function valid(o) return o ~= nil and try(function() return o:IsValid() end) == true end

-- settings.lua, then what was picked in game (choice.txt)
local settings = {}
do
  local ok, s = pcall(dofile, SCRIPTS .. "settings.lua")
  if ok and type(s) == "table" then settings = s else log("settings.lua not read (" .. tostring(s) .. "): defaults") end
  local f = io.open(CHOICE, "r")
  if not f then
    f = io.open(OLD .. "choice.txt", "r")
    if f then log("choice.txt taken over from SBPlayAs (its old name)") end
  end
  if f then
    for line in f:lines() do
      local k, v = line:match("^(%a+)=(%S+)")
      if k == "who" and LABELS[v] then settings.who = v
      elseif k == "voice" or k == "blade" then settings[k] = v ~= "0" end
    end
    f:close()
  end
  if not LABELS[settings.who or "eve"] then log("who = " .. tostring(settings.who) .. " isn't one: eve"); settings.who = "eve" end
end
local function save_choice()
  local f = io.open(CHOICE, "w")
  if not f then return end
  f:write(string.format("who=%s\nvoice=%d\nblade=%d\n", settings.who or "eve", settings.voice == false and 0 or 1,
    settings.blade == false and 0 or 1))
  f:close()
end

-- nothing loaded from the pak for a while after a new Eve (a level loading) or while she is dead (a respawn next): a
-- load then waited on the level's own loading, an endless loading screen (the gore mod's Nexus report)
local quietUntil = 0
-- (windowKey: the menu key's name before the menu)
local ctx = { settings = settings, log = log, try = try, valid = valid, version = VERSION,
  menuKey = settings.menuKey or settings.windowKey or "F4",
  may_load = function() return os.clock() >= quietUntil end }
local function module(name)
  local ok, m = pcall(dofile, SCRIPTS .. name)
  if not ok then log(name .. " not loaded: " .. tostring(m)); return nil end
  m.init(ctx)
  return m
end
local looks, voice = module("looks.lua"), module("voice.lua")
ctx.looks = looks

-- who she plays, her voice and her blade, put on her now and kept for the next start
local menu
function ctx.apply(who, vo, bl, why)
  if not LABELS[who] then return end
  if looks and looks.available(who) == false then
    local dlc = looks.LOOKS[who].dlc
    log(string.format("%s isn't in this game (%s): still %s", LABELS[who], dlc and "needs the NIKKE collaboration content" or "her meshes not found",
      LABELS[settings.who or "eve"]))
    if menu then menu.toast(LABELS[who] .. (dlc and " needs the NIKKE collaboration content" or " isn't in this game")) end
    return
  end
  local same = who == (settings.who or "eve") and vo == (settings.voice ~= false) and bl == (settings.blade ~= false)
  if same then return end
  settings.who, settings.voice, settings.blade = who, vo, bl
  save_choice()
  if looks then looks.apply_now() end
  log(string.format("playing as %s, voice %s, blade %s (%s)", LABELS[who], vo and "hers" or "Eve's", bl and "hers" or "Eve's", why))
  if menu then
    menu.refresh()
    menu.toast("Playing as " .. LABELS[who])
  end
end
menu = module("menu.lua")
-- the same mod under its old name still installed: both would put her look on and fight over it
do
  local f = io.open(OLD .. "Scripts/main.lua", "r")
  if f then
    f:close()
    log("SBPlayAs (this mod's old name) is installed too: delete ue4ss/Mods/SBPlayAs and SBPlayAsText, they fight with this one")
  end
end

local pawn, pawnAddr, pawnSeen = nil, nil, 0
local voiceWho      -- the voice on her cues now (a pick made while she is dead waits)
local pending = {}  -- keys pressed (UE4SS's input thread), run on her tick

local ACTIONS = {
  menu = function() if menu then menu.toggle(pawn, false) end end,
}
-- a key with modifiers fires the plain key's bind too: per key, the bind with the most modifiers wins
local function bind(key, mods, id)
  if type(key) ~= "string" or key == "" then return end
  local cb = function()
    local p = pending[key]
    if not p or #mods > p.n then pending[key] = { n = #mods, id = id } end
  end
  local ok
  if #mods == 0 then ok = pcall(RegisterKeyBind, Key[key], cb)
  else
    local mk = {}
    for _, m in ipairs(mods) do mk[#mk + 1] = ModifierKey[m] end
    ok = pcall(RegisterKeyBind, Key[key], mk, cb)
  end
  if not ok then log("key " .. table.concat(mods, "+") .. (#mods > 0 and "+" or "") .. key .. " not bound") end
end
local MENU_KEY = ctx.menuKey
bind(MENU_KEY, {}, "menu")
-- the arrow keys, for the menu (the engine never sees them down: UE4SS's binds do)
for _, d in ipairs({ { "UP_ARROW", "up" }, { "DOWN_ARROW", "down" }, { "LEFT_ARROW", "left" }, { "RIGHT_ARROW", "right" } }) do
  pcall(RegisterKeyBind, Key[d[1]], function() if menu and menu.state.open then menu.nav[#menu.nav + 1] = d[2] end end)
end

-- a tick of ours that took SLOW_S or more (a hitch in the game): logged with what took it, at most every ERR_S s
local SLOW_S, slowAt, slowN = 0.03, -math.huge, 0
local function slow(t0, t1, t2, t3, t4, t5)
  if t5 - t0 < SLOW_S then return end
  slowN = slowN + 1
  if t5 - slowAt < ERR_S then return end
  log(string.format("slow tick: %.0f ms (menu %.0f, her look %.0f, its frame %.0f, voice %.0f)%s", (t5 - t0) * 1000,
    (t1 - t0) * 1000, (t3 - t2) * 1000, (t4 - t3) * 1000, (t5 - t4) * 1000,
    slowN > 1 and string.format(", %d slow ticks since the last such line", slowN - 1) or ""))
  slowAt, slowN = t5, 0
end
local function tick(c)
  local self = try(function() return c:get() end)
  local a = self and try(function() return self:GetAddress() end)
  if not a then return end
  local now = os.clock()
  if a ~= pawnAddr then
    -- (another of Eve's Blueprint ticking, not the player's: a scene's or photo mode's copy of her. Taken for a new
    -- Eve while hers was paused, it made the mod forget what Eve wore; back on hers, the look on her was taken for her
    -- own, and picking Eve left Tachy's outfit or Scarlet's hair on her, playtest. The player's own only, when the
    -- game says which)
    local gs = try(function() return StaticFindObject("/Script/Engine.Default__GameplayStatics") end)
    local pp = valid(gs) and try(function() return gs:GetPlayerPawn(self, 0) end)
    local ppa = valid(pp) and try(function() return pp:GetAddress() end)
    if ppa and ppa ~= a then return end
    -- a death reloads the level: a new Eve ticks, the old one is freed (never touched again)
    if not ppa and pawnAddr and now - pawnSeen < 1.0 then return end
    if pawnAddr then log("new Eve (the level reloaded)") end
    pawnAddr, pawn = a, self
    quietUntil = math.max(quietUntil, now + 8)
    if looks then looks.forget() end
    if menu then menu.forget() end
  end
  pawnSeen = now
  for key, p in pairs(pending) do
    pending[key] = nil
    local ok, err = pcall(ACTIONS[p.id])
    if not ok then logerr(p.id .. " failed", err) end
  end
  if menu then
    local ok, err = pcall(menu.hook_tick)
    if not ok then logerr("menu", err) end
    ok, err = pcall(menu.tick, pawn)
    if not ok then logerr("menu", err) end
  end
  local t1 = os.clock()
  local mesh = try(function() return pawn.Mesh end)
  if not valid(mesh) then return end
  -- (dead: her body a ragdoll; nothing of hers is swapped then, a pick waits till she is up)
  local dead = try(function() return mesh:IsSimulatingPhysics(FName("Bip001-Pelvis")) end) == true
  if dead then quietUntil = math.max(quietUntil, now + 10) end
  local t2, t3 = os.clock(), nil
  if looks then
    local ok, err = pcall(looks.tick, pawn, mesh, dead)
    if not ok then logerr("look", err) end
    t3 = os.clock()
    if not dead then
      ok, err = pcall(looks.frame, mesh)
      if not ok then logerr("look", err) end
    end
  end
  local t4 = os.clock()
  -- (the voice a pick changes waits, as her look does, till she is up: swapped in her death, at once, the
  -- waves her death sounds played left her cues under them and the game froze for good, playtest)
  if not dead or not voiceWho then voiceWho = settings.voice ~= false and settings.who or "eve" end
  if voice then
    local ok, err = pcall(voice.tick, voiceWho)
    if not ok then logerr("voice", err) end
  end
  slow(now, t1, t2, t3 or t2, t4, os.clock())
end

local hooked = false
local function hook(how)
  if hooked then return true end
  if not valid(try(function() return StaticFindObject(TICK_FN) end)) then return false end
  local okh, e = pcall(RegisterHook, TICK_FN, function(c)
    local okt, et = pcall(tick, c)
    if not okt then logerr("tick", et) end
  end)
  hooked = okh
  log(string.format("tick hook (%s): %s", how, okh and "ok" or tostring(e)))
  return okh
end
pcall(RegisterHook, "/Script/Engine.PlayerController:ClientRestart", function() pcall(hook, "player start") end)
LoopAsync(1000, function() return hooked or hook("loop") end)

log(string.format("StellarBladePlayAs %s loaded: playing as %s, voice %s, blade %s; %s menu", VERSION,
  LABELS[settings.who or "eve"], settings.voice == false and "off" or "on", settings.blade == false and "off" or "on",
  tostring(MENU_KEY)))
