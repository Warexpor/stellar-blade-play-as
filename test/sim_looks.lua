-- StellarBladePlayAs looks.lua: Tachy's body and face on Eve's own components and her hair hidden; what the game puts back set
-- again; never while she is dead (a pick then waits); Raven's hair on a component of its own on her pose; her blade
-- off gives Eve's sword back; Scarlet without the DLC changes nothing; Eve again gives back every mesh and shows what
-- was hidden
local F = require("fake")
local SCRIPTS = assert(os.getenv("SB_SCRIPTS"), "run from test/run.sh")
local print = F.say
local fails = 0
local function check(c, what)
  print((c and "ok   " or "FAIL ") .. what)
  if not c then fails = fails + 1 end
end
-- a mesh with its own materials (Materials[i].MaterialInterface)
local function mats(name, n)
  local l = {}
  for i = 1, n do l[i] = { MaterialInterface = F.obj(name .. "_M" .. i, "MaterialInstanceConstant") } end
  return { ForEach = function(_, f) for i, x in ipairs(l) do f(i, { get = function() return x end }) end end }, l
end
local function asset(path)
  local o = F.obj(path:match("([^.]+)$"), "SkeletalMesh")
  o.Materials, o.mats = mats(path:match("([^.]+)$"), 3)
  F.objects[path] = o
  return o
end
local P = "/Game/Art/Character/"
local tBody = asset(P .. "NPC/CH_NPC_TachyNPC/CH_NPC_TachyNPC_Body.CH_NPC_TachyNPC_Body")
local tFace = asset(P .. "NPC/CH_NPC_TachyNPC/CH_NPC_TachyNPC_Face_Jali2.CH_NPC_TachyNPC_Face_Jali2")
local rBody = asset(P .. "PC/CH_P_EVE_11/CH_P_EVE_11.CH_P_EVE_11")
local rHair = asset(P .. "Monster/CH_M_NA_53/CH_M_NA_53_Hair.CH_M_NA_53_Hair")
local tSword = asset(P .. "Weapon/Sword/CH_W_Sword_02/CH_W_Sword_02.CH_W_Sword_02")
local rBlade = asset(P .. "Monster/CH_M_NA_53/CH_M_NA_53_Weapon.CH_M_NA_53_Weapon")
F.objects["/Script/Engine.SkeletalMeshComponent"] = F.obj("SkeletalMeshComponent", "Class")
local eveBody, eveFace, eveHair = F.obj("CH_P_EVE_01", "SkeletalMesh"), F.obj("CH_P_EVE_Face_Jali3", "SkeletalMesh"), F.obj("CH_P_EVE_Hair", "SkeletalMesh")
local at = {} -- where each component is
local function comp(name, sm)
  local c = F.obj(name, "SkeletalMeshComponent", { SkeletalMesh = sm, vis = true, over = {} })
  -- (what was set on the component stays on by slot number when the mesh changes, as in the engine)
  c.GetNumMaterials = function() return 3 end
  c.GetMaterial = function(self, i) return self.over[i] or (self.SkeletalMesh and self.SkeletalMesh.mats and self.SkeletalMesh.mats[i + 1].MaterialInterface) end
  c.SetMaterial = function(self, i, m) self.over[i] = m end
  c.SetHiddenInGame = function(self, h) self.hid = h end
  c.K2_GetComponentLocation = function(self) return at[self] or { X = 0, Y = 0, Z = 100 } end
  c.SetSkeletalMesh = function(self, m) self.SkeletalMesh = m end
  c.SetVisibility = function(self, v) self.vis = v end
  c.IsVisible = function(self) return self.vis end
  return c
end
local eveSword, eveFolded = F.obj("CH_W_Sword_01", "SkeletalMesh"), F.obj("CH_W_Sword_01_Folded", "SkeletalMesh")
local body, face, hair = comp("Body", eveBody), comp("Face", eveFace), comp("Hair", eveHair)
local sword = comp("Weapon1", eveSword)
local earring = comp("Accessory1", F.obj("CH_P_EVE_01_Earring", "SkeletalMesh"))
-- (her face in Etc1, 14, as in game)
local list = { { MeshSlot = 0, MeshComponent = body }, { MeshSlot = 14, MeshComponent = face }, { MeshSlot = 2, MeshComponent = hair },
  { MeshSlot = 5, MeshComponent = sword }, { MeshSlot = 9, MeshComponent = earring } }
-- her outfit's material instance on her body (the game's, by slot number)
local eveSkin = F.obj("MI_EVE_01_Skin_Dyn", "MaterialInstanceDynamic")
body.over[1] = eveSkin
body.GetSocketLocation = function() return { X = 0, Y = 0, Z = 160 } end
FName = FName or function(s) return s end
local added = {}
local pawn = F.obj("Eve", "CH_P_EVE_01_Blueprint_C", { Mesh = body,
  MeshInfoList = { ForEach = function(_, f) for i, x in ipairs(list) do f(i, { get = function() return x end }) end end } })
pawn.AddComponentByClass = function()
  local c = comp("Extra" .. (#added + 1), nil)
  c.SetMasterPoseComponent = function(self, m) self.master = m end
  c.K2_DestroyComponent = function(self) self.destroyed = true end
  added[#added + 1] = c
  return c
end
local settings = { who = "eve" }
local logs = {}
local ctx = { settings = settings, log = function(s) logs[#logs + 1] = s; print("  | " .. s) end,
  try = function(f) local ok, r = pcall(f); if ok then return r end end, valid = function(x) return x ~= nil and x ~= false end }
local PA = dofile(SCRIPTS .. "looks.lua")
PA.init(ctx)
local function tick(dead) F.t = F.t + 1.1; PA.tick(pawn, body, dead) end

tick()
check(body.SkeletalMesh == eveBody, "Eve: nothing changed")
settings.who = "tachy"
-- (the level loading: nothing loaded from the pak, Tachy's body not in memory yet)
local quiet, held = true, F.objects[P .. "NPC/CH_NPC_TachyNPC/CH_NPC_TachyNPC_Body.CH_NPC_TachyNPC_Body"]
ctx.may_load = function() return not quiet end
StaticFindObject = function(p) if quiet and p:find("TachyNPC_Body", 1, true) then return nil end return F.objects[p] end
tick()
check(body.SkeletalMesh == eveBody and not PA._state().failed[P .. "NPC/CH_NPC_TachyNPC/CH_NPC_TachyNPC_Body.CH_NPC_TachyNPC_Body"],
  "a level loading: Tachy waits, not given up on")
quiet = false
check(held ~= nil, "(her body loadable after)")
tick()
check(body.SkeletalMesh == tBody and face.SkeletalMesh == tFace, "Tachy: her body and face on Eve's components")
check(hair.vis == false, "Eve's hair hidden")
check(sword.SkeletalMesh == tSword, "Tachy's sword in place of Eve's")
check(body:GetMaterial(1) == tBody.mats[2].MaterialInterface and sword:GetMaterial(0) == tSword.mats[1].MaterialInterface,
  "her body and sword in their own materials, not Eve's outfit's")
check(earring.vis == false, "Eve's outfit accessory hidden")
-- her sword folded into her pin (at her head): Tachy's hidden; drawn (away from it): shown
at[sword] = { X = 5, Y = 0, Z = 170 }
PA.frame(body)
check(sword.hid == true, "Tachy's blade in her hairpin: hidden")
at[sword] = { X = 50, Y = 0, Z = 150 }
PA.frame(body)
check(sword.hid == true, "between the pin and her hand: still hidden")
at[sword] = { X = 70, Y = 0, Z = 110 }
PA.frame(body)
check(sword.hid == false, "drawn: shown")
at[sword] = { X = 5, Y = 0, Z = 170 }
PA.frame(body)
-- the gore mod's photo mode: her cut-off head, and the pinned blade with it, onto a copy of her mesh lying where the
-- head fell, 150 cm away; measured from the copy's head it stays hidden
local copy = comp("PieceCopy", tBody)
copy.GetBoneIndex = function() return 7 end
copy.GetSocketLocation = function() return { X = 150, Y = 0, Z = 10 } end
sword.GetAttachParent = function() return copy end
at[sword] = { X = 155, Y = 0, Z = 20 }
PA.frame(body)
check(sword.hid == true, "pinned blade on the photo mode copy of her cut-off head: still hidden")
sword.GetAttachParent = function() return body end
at[sword] = { X = 5, Y = 0, Z = 170 }
PA.frame(body)
body.SkeletalMesh = eveBody -- (the game's outfit put back)
tick()
check(body.SkeletalMesh == tBody, "the game's outfit put back: Tachy's set again")
body.SkeletalMesh = eveBody
tick(true)
check(body.SkeletalMesh == eveBody, "not while she is dead")
tick()
settings.who = "raven"
tick(true)
check(body.SkeletalMesh == tBody and added[1] == nil, "a pick while she is dead waits")
tick()
check(body.SkeletalMesh == rBody and face.SkeletalMesh == eveFace, "Raven: her suit on Eve's body, Eve's face back")
check(added[1] and added[1].SkeletalMesh == rHair and added[1].master == body, "Raven's hair on a component of its own, on Eve's pose")
check(hair.vis == false, "Eve's hair hidden for Raven")
check(sword.SkeletalMesh == rBlade, "Raven's blade in place of Eve's")
sword.SkeletalMesh = eveFolded -- (the game folds her sword away)
tick()
check(sword.SkeletalMesh == eveFolded, "her sword folded away by the game: left as the game has it")
sword.SkeletalMesh = eveSword -- (and draws it again)
tick()
check(sword.SkeletalMesh == rBlade, "drawn again: Raven's blade again")
settings.blade = false
tick()
check(sword.SkeletalMesh == eveSword and body.SkeletalMesh == rBody, "her blade off: Eve's sword back, Raven's suit on")
settings.blade = nil
tick()
check(sword.SkeletalMesh == rBlade, "her blade on again")
settings.who = "scarlet"
tick()
check(body.SkeletalMesh == eveBody and added[1].destroyed and hair.vis == true, "Scarlet without the DLC: back as Eve, nothing else")
local said = false
for _, l in ipairs(logs) do if l:find("needs its DLC") then said = true end end
check(said, "the log says Scarlet needs her DLC")
settings.who = "tachy"; tick()
settings.who = "eve"; tick()
check(body.SkeletalMesh == eveBody and face.SkeletalMesh == eveFace and hair.vis == true and sword.SkeletalMesh == eveSword,
  "Eve again: her own body, face, hair and sword")
check(body:GetMaterial(1) == eveSkin and earring.vis == true and sword.hid == false, "her outfit's materials, accessory and pin back")
PA.frame(body)
check(sword.hid == false, "Eve: her own pin shown")
-- the game puts her outfit on while she looks like Tachy (a new Eve is first seen in her Blueprint's own mesh, the
-- outfit a second later): back to Eve she wears that outfit, in its materials, not the first mesh seen
local outfit, outfitSkin = F.obj("CH_P_EVE_08", "SkeletalMesh"), F.obj("MI_EVE_08_Skin_Dyn", "MaterialInstanceDynamic")
settings.who = "tachy"; tick()
body.SkeletalMesh, body.over[1] = outfit, outfitSkin
tick()
check(body.SkeletalMesh == tBody, "the game's outfit over Tachy's body: Tachy again")
settings.who = "eve"; tick()
check(body.SkeletalMesh == outfit and body:GetMaterial(1) == outfitSkin, "back to Eve: the outfit the game put on, in its materials")
body.SkeletalMesh, body.over[1] = eveBody, eveSkin
print(fails == 0 and "PASS" or "FAIL")
