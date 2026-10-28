-- StellarBladePlayAs voice.lua: Eve's cues keep their graphs and get the other's recordings of the same kind on their wave
-- players; a cue the game loads anew later gets them on the next look; switching gives Eve's back by path (one the
-- garbage collector freed meanwhile loaded again); a recording that isn't there is logged once and skipped
local F = require("fake")
local SCRIPTS = assert(os.getenv("SB_SCRIPTS"), "run from test/run.sh")
local print = F.say
local fails = 0
local function check(c, what)
  print((c and "ok   " or "FAIL ") .. what)
  if not c then fails = fails + 1 end
end
local loads = {}
LoadAsset = function(path) loads[#loads + 1] = path; return F.objects[path] end
local function asset(path, cls)
  local o = F.obj(path:match("([^.]+)$"), cls)
  o.GetFullName = function() return cls .. " " .. path end
  F.objects[path] = o
  return o
end
local function wave(dir, name) return asset("/Game/Sound/Dialogue/ActionVoice/" .. dir .. "/" .. name .. "_VO." .. name .. "_VO", "SoundWave") end
local function arr(list) return { ForEach = function(_, f) for i, x in ipairs(list) do f(i, { get = function() return x end }) end end } end
local function player(w) return F.obj("SoundNodeWavePlayer_0", "SoundNodeWavePlayer", { SoundWave = w }) end
-- a cue as the game's: modulator -> random -> wave players
local function cue(name, waves)
  local ps = {}
  for i, w in ipairs(waves) do ps[i] = player(w) end
  local rnd = F.obj("SoundNodeRandom_0", "SoundNodeRandom", { ChildNodes = arr(ps) })
  local mod = F.obj("SoundNodeModulator_0", "SoundNodeModulator", { ChildNodes = arr({ rnd }) })
  local c = asset("/Game/Sound/Voice/PC/" .. name .. "." .. name:match("([^/]+)$"), "SoundCue")
  c.FirstNode = mod
  return c, ps
end
local e1, e2, e3 = wave("Eve", "vo_eve_atk_l1"), wave("Eve", "vo_eve_atk_l3"), wave("Eve", "vo_eve_atk_l4")
local d1 = wave("Eve", "vo_eve_die_01")
local atkL, pl = cue("eve_vo_attack_L1_Cue", { e1, e2, e3 })
local _, pd = cue("eve_vo_die_Cue", { d1 })
local t = {}
for i = 5, 8 do t[i] = wave("Tachy", "vo_Tachy_Atk_l" .. i) end
-- (one of Tachy's the game doesn't have)
F.objects[t[7].GetFullName():match("^%S+ (.+)$")] = nil
local tdie = wave("Tachy", "vo_Tachy_dmg_xl1")
wave("Tachy", "vo_Tachy_dmg_xl2"); wave("Tachy", "vo_Tachy_dmg_xl3")
local r = {}
for i = 1, 4 do r[i] = wave("Raven", "vo_Raven_atk_l" .. i) end

local logs = {}
local ctx = { log = function(s) logs[#logs + 1] = s; print("  | " .. s) end,
  try = function(f) local ok, x = pcall(f); if ok then return x end end,
  valid = function(x) return x ~= nil and x ~= false and (type(x) ~= "table" or rawget(x, "__dead") ~= true) end }
local V = dofile(SCRIPTS .. "voice.lua")
V.init(ctx)
local function tick(who) F.t = F.t + 3.5; V.tick(who) end
local function has(pat) for _, l in ipairs(logs) do if l:find(pat) then return true end end return false end

tick("eve")
check(pl[1].SoundWave == e1, "Eve: nothing changed")
tick("tachy")
check(pl[1].SoundWave == t[5] and pl[2].SoundWave == t[6], "Tachy's heavy attacks on Eve's heavy attack cue")
check(pl[3].SoundWave == t[8], "a slot whose recording the game lacks: the next of hers")
check(pd[1].SoundWave == tdie, "Tachy's death line on Eve's death cue")
check(atkL.FirstNode.__cls == "SoundNodeModulator", "the cue's graph is Eve's still")
check(has("not found"), "a recording missing from the game: logged")
local n, nl = #logs, #loads
tick("tachy")
check(#logs == n and #loads == nl, "every 3 s after: nothing to do, nothing loaded or logged again")
-- the game loads Eve's cue anew (a level): it gets Tachy's on the next look
local _, pl2 = cue("eve_vo_attack_L1_Cue", { e1, e2, e3 })
tick("tachy")
check(pl2[1].SoundWave == t[5], "a cue loaded anew: Tachy's on it too")
-- Eve's wave freed meanwhile, loaded again by its path
e1.__dead = true
local e1b = wave("Eve", "vo_eve_atk_l1")
tick("raven")
check(pl2[1].SoundWave == r[1] and pl2[2].SoundWave == r[2], "Raven: hers on, Tachy's off")
tick("eve")
check(pl2[1].SoundWave == e1b and pl2[2].SoundWave == e2 and pl2[3].SoundWave == e3 and pl[3].SoundWave == e3, "Eve again: her own back, the freed one loaded again by path")
check(pd[1].SoundWave == d1, "her death cue: her own death line back")
-- a level loading: Raven's not in memory and nothing loaded from the pak: not given up on, on once it is in
local quiet = true
ctx.may_load = function() return not quiet end
StaticFindObject = function(p) if quiet and p:find("Raven", 1, true) then return nil end return F.objects[p] end
local nlog = #logs
tick("raven")
local said = false
for i = nlog + 1, #logs do if logs[i]:find("not found") then said = true end end
check(pl2[1].SoundWave == e1b and not said, "a level loading: Eve's stays, Raven's not given up on")
quiet = false
tick("raven")
check(pl2[1].SoundWave == r[1], "the level in: Raven's on")
print(fails == 0 and "PASS" or "FAIL")
