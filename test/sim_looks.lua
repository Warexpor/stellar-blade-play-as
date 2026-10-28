-- StellarBladePlayAs looks.lua: Tachy's body and face on Eve's own components and her hair and hairpin hidden, Tachy's
-- hair sections hidden on her body and shown alone on a copy at her head, its strands simulated there; what the
-- game puts back set again; never while she is dead or a part of her is off (a pick then waits); her blade hidden
-- while it rides a socket on her head (put away), shown on any other (drawn), hidden again after a scene showed it;
-- Raven's face on a component of its own on her pose, her hair at Eve's head with its strands simulated; her blade
-- off gives Eve's sword back; Scarlet without the DLC changes nothing; with it her hair sections hidden and the game's
-- Scarlet hairstyle for Eve on Eve's hair component; Eve again gives back every mesh and shows what was hidden
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
local rFace = asset(P .. "Monster/CH_M_NA_53/CH_M_NA_53_Facial.CH_M_NA_53_Facial")
rHair.PhysicsAsset = F.obj("CH_M_NA_53_Physics", "PhysicsAsset")
-- (a strand's upper link, a lower one damped as in the asset, her head)
local setups = { { BoneName = F.fname("HBN_LMA02"), DefaultInstance = { LinearDamping = 1, AngularDamping = 5 } },
  { BoneName = F.fname("HBN_LMA07"), DefaultInstance = { LinearDamping = 5, AngularDamping = 30 } },
  { BoneName = F.fname("Bip001-Head"), DefaultInstance = { LinearDamping = 5, AngularDamping = 30 } } }
rHair.PhysicsAsset.SkeletalBodySetups = { ForEach = function(_, f) for i, x in ipairs(setups) do f(i, { get = function() return x end }) end end }
local tSword = asset(P .. "Weapon/Sword/CH_W_Sword_02/CH_W_Sword_02.CH_W_Sword_02")
local rBlade = asset(P .. "Monster/CH_M_NA_53/CH_M_NA_53_Weapon.CH_M_NA_53_Weapon")
F.objects["/Script/Engine.SkeletalMeshComponent"] = F.obj("SkeletalMeshComponent", "Class")
F.objects["/Script/Engine.PoseableMeshComponent"] = F.obj("PoseableMeshComponent", "Class")
F.objects["/Script/Engine.CapsuleComponent"] = F.obj("CapsuleComponent", "Class")
-- Tachy's physics asset: a strand's body and her spine's
local function arr(l) return { ForEach = function(_, f) for i, x in ipairs(l) do f(i, { get = function() return x end }) end end } end
local tBodies = { { BoneName = F.fname("Ab_Hair_L1_03"), DefaultInstance = { LinearDamping = 10, AngularDamping = 40 } },
  { BoneName = F.fname("Bip001-Spine"), DefaultInstance = { LinearDamping = 5, AngularDamping = 30 } } }
tBody.PhysicsAsset = F.obj("CH_NPC_TachyNPC_Body_Physics", "PhysicsAsset", { SkeletalBodySetups = arr(tBodies) })
local eveBody, eveFace, eveHair = F.obj("CH_P_EVE_01", "SkeletalMesh"), F.obj("CH_P_EVE_Face_Jali3", "SkeletalMesh"), F.obj("CH_P_EVE_Hair", "SkeletalMesh")
eveBody.Materials, eveBody.mats = mats("CH_P_EVE_01", 3)
local at = {} -- where each component is
local function comp(name, sm)
  local c = F.obj(name, "SkeletalMeshComponent", { SkeletalMesh = sm, vis = true, over = {} })
  -- (what was set on the component stays on by slot number when the mesh changes, as in the engine)
  c.GetNumMaterials = function() return 3 end
  c.GetMaterial = function(self, i) return self.over[i] or (self.SkeletalMesh and self.SkeletalMesh.mats and self.SkeletalMesh.mats[i + 1].MaterialInterface) end
  c.SetMaterial = function(self, i, m) self.over[i] = m end
  c.SetHiddenInGame = function(self, h) self.hid = h; self.bHiddenInGame = h end
  c.K2_GetComponentLocation = function(self) return at[self] or { X = 0, Y = 0, Z = 100 } end
  c.SetSkeletalMesh = function(self, m) self.SkeletalMesh = m end
  c.SetVisibility = function(self, v) self.vis = v end
  c.IsVisible = function(self) return self.vis end
  -- (its material sections hidden, by material id: kept through a mesh change, as in the engine)
  c.hiddenM = {}
  c.GetNumLODs = function() return 1 end
  c.ShowMaterialSection = function(self, id, _, show) self.hiddenM[id] = not show or nil end
  c.IsMaterialSectionShown = function(self, id) return not self.hiddenM[id] end
  c.ShowAllMaterialSections = function(self) self.hiddenM = {} end
  c.SetAnimInstanceClass = function(self, cls) self.AnimClass = cls end
  return c
end
local eveSword, eveFolded = F.obj("CH_W_Sword_01", "SkeletalMesh"), F.obj("CH_W_Sword_01_Folded", "SkeletalMesh")
local body, face, hair = comp("Body", eveBody), comp("Face", eveFace), comp("Hair", eveHair)
local eveHairAnim = F.obj("EVE_HR_02_AnimBP_C", "AnimBlueprintGeneratedClass")
hair.AnimClass = eveHairAnim
local sword = comp("Weapon1", eveSword)
local earring = comp("Accessory1", F.obj("CH_P_EVE_01_Earring", "SkeletalMesh"))
-- (her face in Etc1, 14, as in game)
local list = { { MeshSlot = 0, MeshComponent = body }, { MeshSlot = 14, MeshComponent = face }, { MeshSlot = 2, MeshComponent = hair },
  { MeshSlot = 5, MeshComponent = sword }, { MeshSlot = 9, MeshComponent = earring } }
-- her hairpin: on her body, in no slot
local hairpin = comp("ACC_HairPin", F.obj("CH_ACC_HairPin", "SkeletalMesh"))
local children = { hairpin }
body.AttachChildren = { ForEach = function(_, f) for i, x in ipairs(children) do f(i, { get = function() return x end }) end end }
-- the skeleton's sockets and bones: her sword put away rides SC_SwordingPoint (on her head), drawn Weapon (on Prop1)
local SOCK = { SC_SwordingPoint = "Bip001-Head", Weapon = "Bip001-Prop1" }
local PARENT = { ["Bip001-Head"] = "Bip001-Neck", ["Bip001-Neck"] = "Bip001-Spine", ["Bip001-Spine"] = "Bip001",
  ["Bip001-Prop1"] = "Bip001", ["Bip001"] = "Root" }
body.GetSocketBoneName = function(_, n) n = tostring(n); return F.fname(SOCK[n] or (PARENT[n] and n) or "None") end
body.GetParentBone = function(_, n) return F.fname(PARENT[tostring(n)] or "None") end
sword.GetAttachParent = function() return body end
local function ride(c, sock) c.AttachSocketName = F.fname(sock) end
ride(sword, "Weapon")
-- (a part of her off: the gore mod's cuts, her own bones simulated)
local offBone
body.IsSimulatingPhysics = function(_, b) return tostring(b) == offBone end
-- her outfit's material instance on her body (the game's, by slot number)
local eveSkin = F.obj("MI_EVE_01_Skin_Dyn", "MaterialInstanceDynamic")
body.over[1] = eveSkin
body.GetSocketLocation = function() return { X = 0, Y = 0, Z = 160 } end
FName = FName or function(s) return s end
local added = {}
local pawn = F.obj("Eve", "CH_P_EVE_01_Blueprint_C", { Mesh = body,
  MeshInfoList = { ForEach = function(_, f) for i, x in ipairs(list) do f(i, { get = function() return x end }) end end } })
pawn.AddComponentByClass = function(_, cls)
  local c = comp("Extra" .. (#added + 1), nil)
  c.cls = cls
  c.SetMasterPoseComponent = function(self, m) self.master = m end
  c.K2_DestroyComponent = function(self) self.destroyed = true end
  c.K2_AttachToComponent = function(self, m, sock, _, _, _, weld) self.parent, self.weld, self.bone = m, weld, sock end
  c.SetCapsuleSize = function(self, r, h) self.capsule = { r, h } end
  c.blocks = {}
  c.SetCollisionObjectType = function(self, ch) self.obj = ch end
  c.SetCollisionResponseToAllChannels = function(self, r) self.blocks = {} end
  c.SetCollisionResponseToChannel = function(self, ch, r) self.blocks[ch] = r == 2 end
  c.sims, c.termed = {}, {}
  c.SetAllBodiesBelowSimulatePhysics = function(self, b, on) self.sims[tostring(b)] = on or nil end
  c.TermBodiesBelow = function(self, b) self.termed[#self.termed + 1] = tostring(b) end
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
check(body.hiddenM[4] and body.hiddenM[5] and not body.hiddenM[0], "her hair's sections hidden on Eve's body, the rest shown")
local th = added[1]
check(th and th.SkeletalMesh == tBody and th.parent == body and tostring(th.bone) == "Bip001-Head" and th.hiddenM[0]
  and th.hiddenM[2] and not th.hiddenM[4], "a copy of her body at Eve's head, only its hair sections shown")
check(th.cls == F.objects["/Script/Engine.PoseableMeshComponent"], "a poseable mesh: its bones posed by spring")
-- (its bones: her head, one strand of three under it, a strand of hers not swung, her spine; made straight down)
local tb = { { "Bip001-Spine", "None", 120 }, { "Bip001-Head", "Bip001-Spine", 150 }, { "Ab_Hair_L1_01", "Bip001-Head", 156 },
  { "Ab_Hair_L1_02", "Ab_Hair_L1_01", 148 }, { "Ab_Hair_L1_03", "Ab_Hair_L1_02", 140 }, { "Ab_Hair_X_01", "Bip001-Head", 150 } }
th.GetNumBones = function() return #tb end
th.GetBoneName = function(_, i) return F.fname(tb[i + 1][1]) end
th.GetParentBone = function(_, b) for _, x in ipairs(tb) do if x[1] == tostring(b) then return F.fname(x[2]) end end return F.fname("None") end
th.GetBoneTransformByName = function(_, b)
  for _, x in ipairs(tb) do
    if x[1] == tostring(b) then return { Rotation = { X = 0, Y = 0, Z = 0, W = 1 }, Translation = { X = 0, Y = 0, Z = x[3] } } end
  end
end
local cw = { X = 0, Y = 0, Z = 0 } -- (the component's place, as her head moves)
th.K2_GetComponentToWorld = function() return { Rotation = { X = 0, Y = 0, Z = 0, W = 1 }, Translation = { X = cw.X, Y = cw.Y, Z = cw.Z } } end
th.posed = {}
th.SetBoneTransformByName = function(self, b, t, space) self.posed[tostring(b)] = { p = t.Translation, q = t.Rotation, space = space } end
th.GetSocketTransform = function() return { Rotation = { X = 0, Y = 0, Z = 0, W = 1 }, Translation = { X = 0, Y = 0, Z = 160 } } end
th.K2_SetRelativeTransform = function(self, t) self.rel = t end
body.GetSocketLocation = function() return { X = 0, Y = 0, Z = -500 } end -- (her neck and chest out of the way)
tick()
check(th.vis == true, "placed and shown")
local said = false
for _, l in ipairs(logs) do if l:find("Tachy's hair: at her head, 3 strand bones swung by spring", 1, true) then said = true end end
check(said, "its strand bones found (not another strand, not her spine)")
PA.frame(body)
local tip = th.posed["Ab_Hair_L1_03"]
check(tip and tip.space == 0 and math.abs(tip.p.X) < 0.01 and math.abs(tip.p.Z - 140) < 0.5 and th.posed["Ab_Hair_L1_01"]
  and not th.posed["Ab_Hair_X_01"] and not th.posed["Bip001-Head"], "first frame: posed as made, in the world, only its strands")
-- (her head moves 10 cm along X: the strands lag, then swing back)
cw.X = 10
F.t = F.t + 1 / 60; PA.frame(body)
local lag = th.posed["Ab_Hair_L1_03"].p.X
check(th.posed["Ab_Hair_L1_01"].p.X == 10 and lag < 9, "her head moved: its root with it, its tip behind (" .. string.format("%.1f", lag) .. ")")
local l1 = th.posed["Ab_Hair_L1_02"].p
local l2 = th.posed["Ab_Hair_L1_03"].p
check(math.abs(math.sqrt((l1.X - l2.X) ^ 2 + (l1.Z - l2.Z) ^ 2) - 8) < 0.01, "its links keep their length")
local q = th.posed["Ab_Hair_L1_02"].q
check(q.Y < -0.01 or q.Y > 0.01, "the bones turned along the swing")
for _ = 1, 240 do F.t = F.t + 1 / 60; PA.frame(body) end
check(math.abs(th.posed["Ab_Hair_L1_03"].p.X - 10) < 1.5, "settled back under her head")
-- (her neck's ball in the strand's way: pushed out)
body.GetSocketLocation = function(_, b) return tostring(b) == "Bip001-Neck" and { X = 12, Y = 0, Z = 140 } or { X = 0, Y = 0, Z = -500 } end
for _ = 1, 30 do F.t = F.t + 1 / 60; PA.frame(body) end
local p = th.posed["Ab_Hair_L1_03"].p
check(math.sqrt((p.X - 12) ^ 2 + p.Y ^ 2 + (p.Z - 140) ^ 2) >= 5.4, "pushed out of the ball on her neck")
body.GetSocketLocation = function() return { X = 0, Y = 0, Z = 160 } end
-- (a teleport: put back as made)
cw.X = 5000
F.t = F.t + 1 / 60; PA.frame(body)
check(math.abs(th.posed["Ab_Hair_L1_03"].p.X - 5000) < 0.01, "a teleport: put back as made")
tick()
check(hair.vis == false, "Eve's hair hidden")
check(sword.SkeletalMesh == tSword, "Tachy's sword in place of Eve's")
check(body:GetMaterial(1) == tBody.mats[2].MaterialInterface and sword:GetMaterial(0) == tSword.mats[1].MaterialInterface,
  "her body and sword in their own materials, not Eve's outfit's")
check(earring.vis == false, "Eve's outfit accessory hidden")
PA.frame(body)
check(hairpin.hid == true, "her hairpin hidden")
hairpin:SetHiddenInGame(false) -- (a scene shows it)
PA.frame(body)
check(hairpin.hid == true, "her hairpin hidden again after a scene showed it")
-- drawn, swung past her head (her hand at it): shown; put away (her sword folded into her pin): hidden
at[sword] = { X = 5, Y = 0, Z = 165 }
PA.frame(body)
check(sword.hid ~= true, "drawn, swung past her head: still shown")
ride(sword, "SC_SwordingPoint")
PA.frame(body)
check(sword.hid == true, "put away (on her head's socket): Tachy's blade hidden")
sword:SetHiddenInGame(false) -- (a cutscene shows it)
PA.frame(body)
check(sword.hid == true, "hidden again after a scene showed it")
ride(sword, "Weapon")
at[sword] = { X = 30, Y = 0, Z = 150 }
PA.frame(body)
check(sword.hid == false, "drawn: shown")
ride(sword, "SC_SwordingPoint")
PA.frame(body)
-- the gore mod's photo mode: her cut-off head, and the pinned blade with it, onto a copy of her mesh lying where the
-- head fell: on the copy's head socket it stays hidden
local copy = comp("PieceCopy", tBody)
copy.GetSocketBoneName, copy.GetParentBone = body.GetSocketBoneName, body.GetParentBone
sword.GetAttachParent = function() return copy end
PA.frame(body)
check(sword.hid == true, "pinned blade on the photo mode copy of her cut-off head: still hidden")
-- (a socket none of them has: by its distance from her head)
sword.GetAttachParent = function() return body end
ride(sword, "SomeSocket")
at[sword] = { X = 5, Y = 0, Z = 170 }
PA.frame(body)
check(sword.hid == true, "an unknown socket at her head: hidden (by distance)")
at[sword] = { X = 70, Y = 0, Z = 110 }
PA.frame(body)
check(sword.hid == false, "an unknown socket away from her head: shown")
ride(sword, "SC_SwordingPoint")
PA.frame(body)
body.SkeletalMesh = eveBody -- (the game's outfit put back)
tick()
check(body.SkeletalMesh == tBody, "the game's outfit put back: Tachy's set again")
body.SkeletalMesh = eveBody
tick(true)
check(body.SkeletalMesh == eveBody, "not while she is dead")
-- a part of her off (the gore mod's cuts): the game's outfit put on meanwhile stays, nothing swapped
offBone = "Bip001-L-UpperArm"
tick()
check(body.SkeletalMesh == eveBody, "a part of her off: nothing swapped")
local saidCut = false
for _, l in ipairs(logs) do if l:find("a part of her is off (Bip001-L-UpperArm", 1, true) then saidCut = true end end
check(saidCut, "the log says why")
offBone = nil
tick()
settings.who = "raven"
tick(true)
check(body.SkeletalMesh == tBody and not th.destroyed, "a pick while she is dead waits")
tick()
check(body.SkeletalMesh == rBody and face.SkeletalMesh == rFace and face:GetMaterial(0) == rFace.mats[1].MaterialInterface,
  "Raven: her suit on Eve's body, her face on Eve's face component in its own materials")
check(th.destroyed and not body.hiddenM[4], "Tachy's hair copy gone, Eve's body's sections all shown")
local rh
for i = 2, #added do if added[i].SkeletalMesh == rHair then rh = added[i] end end
check(rh and rh.SkeletalMesh == rHair and rh.master == nil and rh.vis == false and rh.parent == body and rh.weld == false,
  "her hair on a component of its own, hidden till placed, not welded to her")
-- (its bones posed once it is registered: its head 160 cm up and turned a quarter round Z in its reference pose)
local s2 = math.sqrt(0.5)
rh.GetSocketTransform = function() return { Rotation = { X = 0, Y = 0, Z = s2, W = s2 }, Translation = { X = 10, Y = 0, Z = 160 } } end
rh.SetRelativeT = nil
rh.K2_SetRelativeTransform = function(self, t) self.rel = t end
rh.SetPhysicsAsset = function(self, pa)
  self.pa = pa
  local d = setups[2].DefaultInstance
  self.madeWith = { d.LinearDamping, d.AngularDamping, setups[3].DefaultInstance.AngularDamping }
end
rh.SetAllBodiesBelowSimulatePhysics = function(self, b, on) self.simBelow = on and b or nil end
rh.SetAllBodiesBelowPhysicsBlendWeight = function(self, b, w) self.blendBelow, self.blend = b, w end
rh.IsSimulatingPhysics = function(self) return self.simBelow ~= nil end
rh.GetCollisionEnabled = function() return 2 end
tick()
local r = rh.rel
-- (the inverse: its head at the origin, unturned: q^-1 = (0,0,-s2,s2), T' = -(q^-1 T) = -(0,-10,160))
check(r and math.abs(r.Rotation.Z + s2) < 1e-6 and math.abs(r.Translation.X - 0) < 1e-6 and math.abs(r.Translation.Y - 10) < 1e-6
  and math.abs(r.Translation.Z + 160) < 1e-6, "her hair at Eve's head, its own head's reference pose undone")
check(rh.vis == true and rh.pa == rHair.PhysicsAsset and tostring(rh.simBelow) == "HBn_Root", "shown, its strands simulated on its own physics asset")
local caps = {}
for i = 2, #added do if added[i].capsule and added[i].parent == body and not added[i].destroyed then caps[#caps + 1] = added[i] end end
check(#caps == 12 and caps[1].parent == body and tostring(caps[1].bone) == "Bip001-Pelvis" and caps[1].obj == 7 and caps[1].blocks[6] and not caps[1].blocks[7],
  "capsules on her bones for the hair, blocking only the hair's channel")
check(rh.obj == 6 and rh.blocks[7] and not rh.blocks[6], "her hair blocks only the capsules' channel")
local mw = rh.madeWith
check(mw and mw[1] == 3 and mw[2] == 14 and mw[3] == 30, "its strand bodies made at her damping, upper and lower alike (her head's untouched)")
check(rh.blend == 0.8 and tostring(rh.blendBelow) == "HBn_Root", "80% of its swing shown over the made shape")
-- a strand flung away: put back, simulated again a second later
rh.GetSocketLocation = function(_, b) return tostring(b) == "HBN_LMA09" and { X = 900, Y = 0, Z = 0 } or { X = 0, Y = 0, Z = 160 } end
tick()
check(rh.simBelow == nil, "a strand far from her head: put back as made")
check(setups[2].DefaultInstance.LinearDamping == 5 and setups[2].DefaultInstance.AngularDamping == 30, "the asset's own damping back (the boss uses it)")
rh.GetSocketLocation = function() return { X = 0, Y = 0, Z = 160 } end
tick()
check(rh.simBelow ~= nil, "simulated again")
-- (something turned them off, took its physics asset off and made it follow her body's pose)
rh.simBelow, rh.MasterPoseComponent = nil, body
rh.GetPhysicsAsset = function(self) return self.pa end
rh.pa = nil
rh.SetMasterPoseComponent = function(self, m) self.MasterPoseComponent = m end
PA.frame(body)
check(rh.simBelow ~= nil and rh.pa == rHair.PhysicsAsset and rh.MasterPoseComponent == nil,
  "turned off: its physics asset back, its own pose, simulated again the same frame")
local saidStop = false
for _, l in ipairs(logs) do
  if l:find("its strands stopped (", 1, true) and l:find("it followed", 1, true) and l:find("its physics asset was none", 1, true) then saidStop = true end
end
check(saidStop, "what stopped them logged, with what it had lost")
for _ = 1, 3 do rh.simBelow = nil; PA.frame(body) end
F.t = F.t + PA.STOPS_S
rh.simBelow = nil; PA.frame(body)
local every = false
for _, l in ipairs(logs) do if l:find("stopped on 5 of the 5 frames", 1, true) and l:find("every frame", 1, true) then every = true end end
check(every, "how often they stop logged")
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
check(body.SkeletalMesh == eveBody and rh.destroyed and hair.vis == true and face.SkeletalMesh == eveFace,
  "Scarlet without the DLC: back as Eve, nothing else")
check(caps[1].destroyed and caps[10].destroyed, "Raven's capsules gone with her hair")
local said = false
for _, l in ipairs(logs) do if l:find("needs its DLC") then said = true end end
check(said, "the log says Scarlet needs her DLC")
settings.who = "tachy"; tick()
-- (the game made an instance of Tachy's material on a slot of her body)
local mid = F.obj("MID_Tachy_M3", "MaterialInstanceDynamic", { Parent = tBody.mats[3].MaterialInterface })
body.over[2] = mid
settings.who = "eve"; tick()
check(body.SkeletalMesh == eveBody and face.SkeletalMesh == eveFace and hair.vis == true and sword.SkeletalMesh == eveSword,
  "Eve again: her own body, face, hair and sword")
check(body:GetMaterial(1) == eveSkin and earring.vis == true and sword.hid == false and hairpin.hid == false,
  "her outfit's materials, accessory, sword and hairpin back")
check(body:GetMaterial(0) == eveBody.mats[1].MaterialInterface and body:GetMaterial(2) == eveBody.mats[3].MaterialInterface,
  "no material of Tachy's left on her, nor the game's instance of one")
body.over[2] = mid -- (the game sets its instance again)
tick()
check(body:GetMaterial(2) == eveBody.mats[3].MaterialInterface, "the game's instance of Tachy's set again a second later: her own again")
PA.frame(body)
check(sword.hid == false, "Eve: her own pin shown")
-- the game puts her outfit on while she looks like Tachy (a new Eve is first seen in her Blueprint's own mesh, the
-- outfit a second later): back to Eve she wears that outfit, in its materials, not the first mesh seen
local outfit, outfitSkin = F.obj("CH_P_EVE_08", "SkeletalMesh"), F.obj("MI_EVE_08_Skin_Dyn", "MaterialInstanceDynamic")
outfit.Materials, outfit.mats = mats("CH_P_EVE_08", 3)
settings.who = "tachy"; tick()
body.SkeletalMesh, body.over[1] = outfit, outfitSkin
tick()
check(body.SkeletalMesh == tBody, "the game's outfit over Tachy's body: Tachy again")
settings.who = "eve"; tick()
check(body.SkeletalMesh == outfit and body:GetMaterial(1) == outfitSkin, "back to Eve: the outfit the game put on, in its materials")
check(body:GetMaterial(0) == outfit.mats[1].MaterialInterface and body:GetMaterial(2) == outfit.mats[3].MaterialInterface,
  "the slots the game left as Tachy's: that outfit's own, not her first outfit's by slot number")
body.SkeletalMesh, body.over[1] = eveBody, eveSkin
-- Scarlet with the DLC: her body, her face on Eve's face component, her blade turned back from Eve's socket's pitch
local sBody = asset("/Game/DLC_2/Art/Character/Monster/CH_M_NA_961/CH_M_NA_961.CH_M_NA_961")
local sFace = asset("/Game/DLC_2/Art/Character/Monster/CH_M_NA_961/CH_M_NA_961_Facial.CH_M_NA_961_Facial")
local sBlade = asset("/Game/DLC_2/Art/Character/Monster/CH_M_NA_961/CH_M_NA_961_Weapon_01.CH_M_NA_961_Weapon_01")
local sHair = asset("/Game/DLC_2/Art/Character/PC/00_HR/EVE_HR_Nikke_01/EVE_HR_Nikke_01.EVE_HR_Nikke_01")
local sHairAnim = F.obj("EVE_HR_Nikke_01_AnimBP_C", "AnimBlueprintGeneratedClass")
F.objects["/Game/DLC_2/Art/Character/PC/00_HR/EVE_HR_Nikke_01/EVE_HR_Nikke_01_AnimBP.EVE_HR_Nikke_01_AnimBP_C"] = sHairAnim
local sPost = F.obj("CH_P_EVE_Nikke_01_AnimBP_C", "AnimBlueprintGeneratedClass")
-- (the class not loaded by itself: the game's Scarlet outfit for Eve, whose post process it is)
F.objects["/Game/DLC_2/Art/Character/PC/CH_P_EVE_Nikke_01/CH_P_EVE_Nikke_01.CH_P_EVE_Nikke_01"] =
  F.obj("CH_P_EVE_Nikke_01", "SkeletalMesh", { PostProcessAnimBlueprint = sPost })
local postOnWear
do
  local set = body.SetSkeletalMesh
  body.SetSkeletalMesh = function(self, m, r) if m == sBody then postOnWear = m.PostProcessAnimBlueprint end return set(self, m, r) end
end
PA._state().failed = {}
sword.RelativeRotation = { Pitch = 0, Yaw = 0, Roll = 0 }
sword.K2_SetRelativeRotation = function(self, r) self.RelativeRotation = { Pitch = r.Pitch, Yaw = r.Yaw, Roll = r.Roll } end
ride(sword, "Weapon")
settings.who = "scarlet"; tick()
check(body.SkeletalMesh == sBody and face.SkeletalMesh == sFace and face.vis == true and face:GetMaterial(0) == sFace.mats[1].MaterialInterface,
  "Scarlet: her body and her face, in its own materials")
check(sword.SkeletalMesh == sBlade and sword.RelativeRotation.Pitch == 90, "her blade turned Pitch 90 in Eve's Weapon socket")
check(body.hiddenM[3] and body.hiddenM[4] and body.hiddenM[5] and not body.hiddenM[2], "her body's hair, hat and fur sections hidden")
check(hair.SkeletalMesh == sHair and hair.AnimClass == sHairAnim and hair.vis == true and hair:GetMaterial(0) == sHair.mats[1].MaterialInterface,
  "the game's Scarlet hairstyle for Eve on Eve's hair component, its AnimBP running, shown")
check(postOnWear == sPost and sBody.PostProcessAnimBlueprint == nil,
  "her skirt's and tail's AnimBP (the game's Scarlet outfit for Eve's) her body's post process as it went on, off the asset after")
hair.SkeletalMesh, hair.AnimClass = eveHair, eveHairAnim -- (the game puts her hair back)
tick()
check(hair.SkeletalMesh == sHair and hair.AnimClass == sHairAnim, "the game put her hair back: Scarlet's again")
body.hiddenM = {} -- (her body's sections shown again, a mesh change of the game's)
tick()
check(body.hiddenM[5], "her body's hair hidden again")
sword.RelativeRotation = { Pitch = 0, Yaw = 0, Roll = 0 } -- (the game attaches it again, snapped)
PA.frame(body)
check(sword.RelativeRotation.Pitch == 90, "the game set it back: turned again that frame")
settings.who = "eve"; tick()
check(sword.SkeletalMesh == eveSword and sword.RelativeRotation.Pitch == 0 and face.SkeletalMesh == eveFace, "Eve: her sword unturned, her face back")
check(hair.SkeletalMesh == eveHair and hair.AnimClass == eveHairAnim and hair.vis == true and not body.hiddenM[5],
  "her own hair and its AnimBP back, her body's sections all shown")
check(sBody.PostProcessAnimBlueprint == nil, "the boss's body without a post process still")
PA.frame(body)
check(sword.RelativeRotation.Pitch == 0, "and left so")
-- Raven, her death and respawn (the game puts her outfit on as she gets up), then Eve: her outfit, not Raven's suit
-- (playtest: back to Eve she still wore it). Raven's suit put on her again in the seconds after (what put it back
-- unknown): hers again
settings.who = "raven"; tick()
check(body.SkeletalMesh == rBody, "Raven again")
tick(true)
body.SkeletalMesh, body.over[1] = outfit, outfitSkin -- (the respawn's outfit)
tick()
check(body.SkeletalMesh == rBody, "up again: Raven's suit set again over the outfit the game put on")
settings.who = "eve"; tick()
check(body.SkeletalMesh == outfit and body:GetMaterial(1) == outfitSkin, "Eve: the outfit the game put on, in its materials")
local told = false
for _, l in ipairs(logs) do if l:find("back to Eve: her body CH_M_NA_53_Body", 1, true) or l:find("back to Eve: her body ", 1, true) and l:find("0 slot%(s%) still") then told = true end end
check(told, "the log says what she wears now")
body.SkeletalMesh = rBody -- (Raven's suit on her again)
tick()
check(body.SkeletalMesh == outfit and body:GetMaterial(0) == outfit.mats[1].MaterialInterface, "Raven's suit on her again after Eve: her outfit put back")
print(fails == 0 and "PASS" or "FAIL")
