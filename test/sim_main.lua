-- StellarBladePlayAs main.lua in a scratch game folder: it loads with its settings and hooks Eve's tick; its DLL (faked: it
-- answers the hook file and SBSnapShot's "T" commands) is asked for the text; F4 opens the in-game menu (UMG faked:
-- widgets made, every text set recorded), the arrow keys go through the names (shown on the right with her picture,
-- Tachy's your own from portraits/), Enter picks one and goes to Apply, Enter there applies; her voice turned off and
-- applied from its row; Backspace closes and gives the game its input back; not over the Gore mod's F3 menu; F4 its one key
-- (no Shift+F4); started again, it comes back as picked; with no DLL and no FText from UE4SS there is no menu, said why
local F = require("fake")
local SCRIPTS = assert(os.getenv("SB_SCRIPTS"), "run from test/run.sh")
local print = F.say
local fails = 0
local function check(c, what)
  print((c and "ok   " or "FAIL ") .. what)
  if not c then fails = fails + 1 end
end
local DIR = "ue4ss/Mods/StellarBladePlayAs/"
local function read(p) local f = io.open(p, "r"); if not f then return nil end; local s = f:read("a"); f:close(); return s end
local function write(p, s) local f = assert(io.open(p, "w")); f:write(s); f:close() end
local TICK = "/Game/Art/Character/PC/CH_P_EVE_01/Blueprints/CH_P_EVE_01_Blueprint.CH_P_EVE_01_Blueprint_C:ReceiveTick"
F.objects[TICK] = F.obj("ReceiveTick", "Function")

-- ---- UMG, faked: what the menu makes, and every text it sets (by the DLL's T command, or UE4SS's FText) ----
local texts = {}  -- text block address -> its text
local shown = {}  -- widgets on the viewport
local brushes = {} -- images' textures
for _, c in ipairs({ "UserWidget", "WidgetTree", "CanvasPanel", "Image", "TextBlock" }) do
  F.objects["/Script/UMG." .. c] = F.obj(c, "Class")
end
F.objects["/Script/UMG.TextBlock:SetText"] = F.obj("SetText", "Function")
F.objects["/Script/SB.SBCheatManager:SBSnapShot"] = F.obj("SBSnapShot", "Function")
local function slot() return F.obj("CanvasPanelSlot", "CanvasPanelSlot") end
StaticConstructObject = function(cls, outer, name)
  local c = cls.__name
  local o = F.obj(tostring(name), c)
  if c == "CanvasPanel" then o.AddChildToCanvas = function() return slot() end
  elseif c == "UserWidget" then
    o.AddToViewport = function(self) shown[self] = true end
    o.IsInViewport = function(self) return shown[self] == true end
  elseif c == "TextBlock" then
    o.Font = {}
    o.SetText = function(self, t) texts[self.__addr] = t.s end
  elseif c == "Image" then
    o.SetBrushFromTexture = function(self, t) brushes[self.__addr] = t end
  end
  return o
end
local function has_text(s) for _, t in pairs(texts) do if t == s then return true end end return false end
local function picture(name) for _, t in pairs(brushes) do if t.__name == name then return true end end return false end
local gi = F.obj("GameInstance", "GameInstance")
F.classes.GameInstance = { gi }
F.objects["/Script/UMG.Default__WidgetLayoutLibrary"] = F.obj("Default__WidgetLayoutLibrary", "WidgetLayoutLibrary", {
  GetViewportSize = function() return { X = 2560, Y = 1440 } end, GetViewportScale = function() return 1 end,
  GetMousePositionOnViewport = function() return { X = 0, Y = 0 } end })
local modes = {}
F.objects["/Script/UMG.Default__WidgetBlueprintLibrary"] = F.obj("Default__WidgetBlueprintLibrary", "WidgetBlueprintLibrary", {
  SetInputMode_GameAndUIEx = function() modes[#modes + 1] = "ui" end,
  SetInputMode_GameOnly = function() modes[#modes + 1] = "game" end })
for _, p in ipairs({ "/Game/DLC_2/Art/UI/Texture/eve_result.eve_result",
    "/Game/Art/UI/Texture/Album/NPC/image/CH_NPC_TachyNPC.CH_NPC_TachyNPC",
    "/Game/Art/UI/Texture/Album/NPC/image/CH_NPC_Raven.CH_NPC_Raven" }) do
  F.objects[p] = F.obj(p:match("([^.]+)$"), "Texture2D", { size = 512 })
  F.objects[p].Blueprint_GetSizeX = function(self) return self.size end
end
-- (Raven's in memory but not loaded through yet: no size till it is loaded)
local ravenTex = F.objects["/Game/Art/UI/Texture/Album/NPC/image/CH_NPC_Raven.CH_NPC_Raven"]
ravenTex.size = 0

-- the DLL, faked: the hook file answered on the next look, SBSnapShot's commands carried out
local dll = true
local snaps = 0
F.cdo.SBSnapShot = function(self, s)
  snaps = snaps + 1
  if s == "T?" then write(DIR .. "playas.ans", "ok"); return end
  local a, str = s:match("^T(%x+),%x+;(.*)$")
  if a then texts[tonumber(a, 16)] = str end
end
local function dll_look()
  if dll and read(DIR .. "playas.hook") then
    os.remove(DIR .. "playas.hook")
    write(DIR .. "playas.ok", "ok patched, FText at exe+285d510, GMalloc at exe+706b500")
  end
end

-- her controller: the keys held down (IsInputKeyDown)
local down, tapped = {}, {}
local pc = F.obj("PC", "SBNetworkPlayerController", {
  IsInputKeyDown = function(_, k) return down[tostring(k.KeyName)] == true end,
  WasInputKeyJustPressed = function(_, k) return tapped[tostring(k.KeyName)] == true end })
F.objects["/Script/Engine.Default__GameplayStatics"] = F.obj("Default__GameplayStatics", "GameplayStatics", {
  GetPlayerController = function() return pc end })
local function start()
  F.binds, F.hooks, F.loops = {}, {}, {}
  dofile(SCRIPTS .. "main.lua")
  for _, l in ipairs(F.loops) do l.cb() end
end
local body = F.obj("Body", "SkeletalMeshComponent", { SkeletalMesh = F.obj("CH_P_EVE_01", "SkeletalMesh") })
body.IsSimulatingPhysics = function() return false end
local pawn = F.obj("Eve", "CH_P_EVE_01_Blueprint_C", { Mesh = body, Controller = pc,
  MeshInfoList = { ForEach = function() end } })
local function tick(n) for _ = 1, n or 1 do F.t = F.t + 0.05; F.fire(TICK, F.param(pawn)); dll_look(); tapped = {} end end
local function key(k) down[k] = true; tick(); down[k] = nil; tick() end
-- a pick through the menu: opened (on the one playing), down rows down, Enter picks, Enter on Apply, Backspace
local function via_menu(rows)
  F.t = F.t + 0.4
  F.press("F4")
  tick()
  for _ = 1, rows do F.press("DOWN_ARROW"); tick() end
  key("Enter"); key("Enter"); key("BackSpace")
end
local function choice() return read(DIR .. "choice.txt") or "" end
local function log() return read(DIR .. "stellarbladeplayas.log") or "" end

os.remove(DIR .. "choice.txt")
start()
check(#F.hooks[TICK] == 1, "Eve's tick hooked")
tick(3)
check(log():find("StellarBladePlayAsText: ok patched") ~= nil, "its DLL hooked onto SBSnapShot")
check(F.press("F4"), "F4 bound")
tick()
check(log():find("menu: opened") ~= nil and next(shown) ~= nil, "F4: the menu made and on screen")
check(has_text("Play As") and has_text("Eve") and has_text("Tachy") and has_text("Scarlet") and has_text("Playing"),
  "its title, the names, Eve PLAYING (the DLL's text)")
check(picture("eve_result") and has_text("Characters") and has_text("Adjust"), "Eve's picture on the right, its tab and key hints")
check(modes[#modes] == "ui", "the mouse freed for it")
-- a picture of your own for Tachy (portraits/tachy.png), read by the engine
os.execute("mkdir -p " .. DIR .. "portraits")
write(DIR .. "portraits/tachy.png", "png")
local imported
F.objects["/Script/Engine.Default__KismetRenderingLibrary"] = F.obj("Default__KismetRenderingLibrary", "KismetRenderingLibrary", {
  ImportFileAsTexture2D = function(_, _, path) imported = path; return F.obj("Texture2D_own", "Texture2D", {
    Blueprint_GetSizeX = function() return 1920 end, Blueprint_GetSizeY = function() return 1080 end }) end })
-- Down: Tachy shown; Down again: Raven shown; Up: Tachy; nothing picked or applied by it
F.press("DOWN_ARROW")
tick()
check(picture("Texture2D_own") and imported == DIR .. "portraits/tachy.png" and has_text("Tachy's body, face and hair, her sword and her voice. Eve's moves and skills. Enter picks her, then Apply puts her on."), "Down: Tachy's picture, yours from portraits/tachy.png")
F.press("DOWN_ARROW")
tick()
local early = picture("CH_NPC_Raven")
ravenTex.size = 512 -- (the game finishes loading it)
tick(12)
check(not early and picture("CH_NPC_Raven"),
  "Down: Raven's picture in memory without its size not put on half loaded, put on once it is (looked for twice a second)")
F.press("UP_ARROW")
tick()
check(choice():find("who=eve", 1, true) == nil and choice():find("who=", 1, true) == nil, "nothing applied by moving")
key("Enter")
check(has_text("Picked") and choice() == "", "Enter on Tachy: picked, not applied, the focus on Apply")
key("Enter")
check(choice():find("who=tachy", 1, true) ~= nil, "Enter on Apply: Tachy applied, saved")
check(has_text("Playing as Tachy"), "a toast says so")
-- her voice off: its row (two up from Apply), Enter turns it, Apply (two down) applies
F.press("UP_ARROW"); F.press("UP_ARROW")
tick()
check(has_text("Voice") and has_text("On"), "on Voice: On")
key("Enter")
check(has_text("Off") and choice():find("voice=1", 1, true) ~= nil, "Enter: Off, not applied yet")
F.press("DOWN_ARROW"); F.press("DOWN_ARROW")
tick()
key("Enter")
check(choice():find("who=tachy\nvoice=0", 1, true) ~= nil, "Apply: her voice off, saved")
key("BackSpace")
check(log():find("menu: closed") ~= nil and modes[#modes] == "game", "Backspace: closed, the game's input back")
-- (a tap on the controller within one long frame, a hitch: never seen down, only just pressed)
F.t = F.t + 0.4
F.press("F4"); tick()
local closes = select(2, log():gsub("menu: closed", ""))
tapped["Gamepad_FaceButton_Right"] = true; tick()
check(select(2, log():gsub("menu: closed", "")) == closes + 1, "B / Circle tapped within one frame: closed")
F.t = F.t + 0.4
-- the Gore mod's F3 menu open: not over it
F.classes.UserWidget = { F.obj("SBGore_Menu_17", "UserWidget", { IsInViewport = function() return true end,
  GetVisibility = function() return 3 end }) }
F.press("F4")
tick()
check(log():find("not opened: the Gore mod's F3 menu is open") ~= nil, "F4 with the Gore mod's F3 menu open: not opened")
F.classes.UserWidget = nil
-- F4 its one key: Shift+F4 does nothing of its own
check(not F.press("F4", "SHIFT"), "Shift+F4: not bound")
via_menu(1)
check(choice():find("who=raven", 1, true) ~= nil and has_text("Playing as Raven"), "the menu: Raven, a toast")
-- without the NIKKE content (no Scarlet here), once things may load: her row says so, and picking her changes nothing
for _, p in ipairs({ "/Game/Art/Character/NPC/CH_NPC_TachyNPC/CH_NPC_TachyNPC_Body.CH_NPC_TachyNPC_Body",
  "/Game/Art/Character/PC/CH_P_EVE_11/CH_P_EVE_11.CH_P_EVE_11" }) do F.objects[p] = F.objects[p] or F.obj(p:match("([^.]+)$"), "SkeletalMesh") end
F.t = F.t + 12
tick()
F.t = F.t + 0.4
F.press("F4")
tick()
check(has_text("Needs DLC"), "the menu: her row says Needs DLC")
key("BackSpace")
via_menu(1)
check(choice():find("who=raven", 1, true) ~= nil and log():find("Scarlet: .* not found %(needs its DLC%)") ~= nil,
  "no Scarlet in the game: picking her changes nothing")
check(#F.errors == 0, "no errors (" .. table.concat(F.errors, "; ") .. ")")
-- started again: as picked
start()
check(log():find("playing as Raven, voice off") ~= nil, "started again: Raven, voice off")
-- no DLL, and UE4SS without the FText constructor: no menu, said why
os.remove(DIR .. "playas.ok")
dll, texts, shown = false, {}, {}
F.objects["/Script/SB.SBCheatManager:SBSnapShot"] = F.obj("SBSnapShot", "Function")
write("ue4ss/UE4SS.log", "[Lua] Failed to find FText::FText(FString&&)\n")
start()
tick(3)
F.t = F.t + 6
tick()
check(log():find("StellarBladePlayAsText: no answer in 5 s") ~= nil, "no DLL: told after 5 s")
F.press("F4")
tick()
check(log():find("menu: not made: .*settings.lua's who still picks") ~= nil and next(shown) == nil, "F4: no menu, said why")

-- installed before under its old name: its pick taken over once, and the old folder still there is told
os.remove(DIR .. "choice.txt")
local OLD = "ue4ss/Mods/SBPlayAs/"
os.execute("mkdir -p " .. OLD .. "Scripts")
write(OLD .. "choice.txt", "who=raven\nvoice=0\nblade=1\n")
write(OLD .. "Scripts/main.lua", "")
start()
check(log():find("taken over from SBPlayAs") ~= nil and log():find("playing as Raven, voice off") ~= nil, "SBPlayAs's pick taken over")
check(log():find("SBPlayAs %(this mod's old name%) is installed too") ~= nil, "the old one still installed: told")
os.execute("rm -rf ue4ss/Mods/SBPlayAs")
check(#F.errors == 0, "no errors (" .. table.concat(F.errors, "; ") .. ")")

-- a pick made while she is dead (the menu in her death): her voice waits till she is up, as her look does (swapped at
-- once, the game froze for good, playtest)
local function wv(dir, name)
  local path = "/Game/Sound/Dialogue/ActionVoice/" .. dir .. "/" .. name .. "_VO." .. name .. "_VO"
  local o = F.obj(name .. "_VO", "SoundWave")
  o.GetFullName = function() return "SoundWave " .. path end
  F.objects[path] = o
  return o
end
local eveWave = wv("Eve", "vo_eve_atk_l1")
for i = 5, 8 do wv("Tachy", "vo_Tachy_Atk_l" .. i) end
local wp = F.obj("SoundNodeWavePlayer_0", "SoundNodeWavePlayer", { SoundWave = eveWave })
local function arr(list) return { ForEach = function(_, f) for i, x in ipairs(list) do f(i, { get = function() return x end }) end end } end
local atk = F.obj("eve_vo_attack_L1_Cue", "SoundCue", { FirstNode = F.obj("SoundNodeRandom_0", "SoundNodeRandom", { ChildNodes = arr({ wp }) }), VolumeMultiplier = 0.8 })
F.objects["/Game/Sound/Voice/PC/eve_vo_attack_L1_Cue.eve_vo_attack_L1_Cue"] = atk
write(DIR .. "choice.txt", "who=eve\nvoice=1\nblade=1\n")
dll = true
os.remove("ue4ss/UE4SS.log")
start()
tick(3)
local dead = true
body.IsSimulatingPhysics = function() return dead end
via_menu(1)
F.t = F.t + 4
tick(3)
check(choice():find("who=tachy", 1, true) ~= nil and wp.SoundWave == eveWave, "picked in her death: Tachy, her voice waits")
dead = false
F.t = F.t + 4
tick(3)
check(wp.SoundWave ~= eveWave and tostring(wp.SoundWave.__name):find("Tachy") ~= nil, "up again: Tachy's voice on")
body.IsSimulatingPhysics = function() return false end
-- a scene's copy of her (her Blueprint, not the player's pawn) ticking while hers is paused: not taken for a new Eve
local gsObj = F.objects["/Script/Engine.Default__GameplayStatics"]
gsObj.GetPlayerPawn = function() return pawn end
local copy = F.obj("Eve_Seq", "CH_P_EVE_01_Blueprint_C", { Mesh = body, MeshInfoList = { ForEach = function() end } })
local news = select(2, log():gsub("new Eve", ""))
for _ = 1, 40 do F.t = F.t + 0.05; F.fire(TICK, F.param(copy)) end
tick(2)
check(select(2, log():gsub("new Eve", "")) == news, "a scene's copy of her ticking for 2 s: still the player's Eve, nothing forgotten")
gsObj.GetPlayerPawn = nil
check(#F.errors == 0, "no errors (" .. table.concat(F.errors, "; ") .. ")")
os.remove(DIR .. "choice.txt")
os.remove("ue4ss/UE4SS.log")
os.remove(DIR .. "portraits/tachy.png")
print(fails == 0 and "PASS" or "FAIL")
