-- looks.lua: Eve wears another character (settings.who). Her own components take the other's meshes, so her
-- animations, physics and everything another mod does with her body (the gore mod's cuts, struggle, death face) stay
-- hers:
--   tachy: her NPC body and face (CH_NPC_TachyNPC_Body, _Face_Jali2: built on Eve's skeleton, the beach scenes' Tachy),
--     Eve's hair hidden. Her hair is in her body (its materials 4 and 5), moved by her NPC's own rig: on Eve's mesh it
--     hung still, and her strands' bodies never simulated there (playtests). Those sections are hidden on Eve's body
--     (hideMats), and a second copy of her body at Eve's head shows only them (extras' only), a poseable mesh whose
--     strands are swung in Lua (M.SPRING): simulated as Raven's are, they stopped on nearly every frame (playtests)
--   scarlet: the DLC boss's body (CH_M_NA_961, on Eve's skeleton, her head's skin in it) and face (CH_M_NA_961_Facial,
--     skinned to the head and neck). Her hair, hat and its fur (the body's materials 3-5) are hidden on it and the game's
--     own cut of them for Eve, EVE_HR_Nikke_01 (the NIKKE content's Scarlet hairstyle, its KawaiiPhysics AnimBP its
--     post process) goes on Eve's hair component (look.hair): in her body they had no AnimBP to move them and hung
--     still (playtest). Her skirt, tail and the straps on her legs are moved by the boss's AnimBP too (KawaiiPhysics), and
--     on Eve they hung still (playtest): the body takes the game's own Scarlet outfit for Eve's post process AnimBP
--     (look.post: CH_P_EVE_Nikke_01's, KawaiiPhysics on the same 71 bones: taken from that mesh, its class alone
--     wasn't loaded, playtest), set on the mesh asset while she wears it.
--     Eve's ponytails hidden. Her blade points along its mesh's X (Eve's
--     and Raven's along Z): the boss holds it on a bone of her hand as it is (SC_Weapon2 on SC_WeaponConstraint, the
--     bone Eve's Prop1 follows), and Eve's Weapon socket turns what it holds Pitch -90, so it is turned back
--     (weaponTurn, again each frame the game set it back). Without the DLC it isn't found and nothing changes
--   raven: Raven's suit as Eve's outfit (CH_P_EVE_11); her face (CH_M_NA_53_Facial, on her own skeleton but skinned to
--     the head and neck only) on Eve's face component, posed by Eve's body as Eve's face is (bones by name), so another
--     mod's work on Eve's face takes it (the gore mod's neck cut); her hair (CH_M_NA_53_Hair) on a component of its
--     own at Eve's head, its strands simulated (M.STRANDS): the boss swings them with her own AnimBP, and posed by
--     Eve's body they never moved (playtest); Eve's hair hidden
-- Each takes her own blade too (the game's EquipmentTable: Tachy_Sword, Raven_Blade, Scarlet_Sword) in place of
-- Eve's drawn sword (CH_W_Sword_01 in a weapon slot; the folded one the game shows when it is away is left, so it
-- still goes away as hers): on a skeleton of its own, it doesn't fold, and her sword's gore (its fall, a blade cut
-- through it) takes it as it took hers.
-- Each mesh goes on with its own materials (Eve's outfit's, set on her components, made the others' parts wrong or
-- glowing), Eve's outfit accessories and her hairpin (CH_ACC_HairPin: the others have no ponytail it holds) are hidden,
-- and another's blade folded into her hairpin (it doesn't fold) too.
-- What the game puts back (a level, a respawn, the outfit menu, a scene) is set again within a second; "eve" gives
-- back what she wore. While it is on, an outfit change in the game's menu is overridden. settings.blade false: her
-- own sword stays. Nothing of hers is swapped while a part of her is off (the gore mod's cuts: her limbs' own bones
-- simulated): an outfit swapped under a fresh cut crashed the game (playtest: another mod put her suit on as her
-- shield broke, the gore mod took her arm, this put Raven's suit back over it)
local M = {}
local ctx, try, valid
local function cfg() return ctx.settings or {} end
local function log(s) ctx.log("look: " .. s) end

local P = "/Game/Art/Character/"
M.LOOKS = {
  tachy = { label = "Tachy", body = P .. "NPC/CH_NPC_TachyNPC/CH_NPC_TachyNPC_Body.CH_NPC_TachyNPC_Body",
    face = P .. "NPC/CH_NPC_TachyNPC/CH_NPC_TachyNPC_Face_Jali2.CH_NPC_TachyNPC_Face_Jali2", hide = { hair = true },
    hideMats = { 4, 5 },
    extras = { { path = P .. "NPC/CH_NPC_TachyNPC/CH_NPC_TachyNPC_Body.CH_NPC_TachyNPC_Body", name = "Tachy's hair", head = true,
      only = { 4, 5 }, prefix = "Ab_Hair_",
      spring = { "Ab_Hair_KL01", "Ab_Hair_KR01", "Ab_Hair_L1_01", "Ab_Hair_L2_01", "Ab_Hair_L3_01", "Ab_Hair_L4_01", "Ab_Hair_R1_01",
        "Ab_Hair_R2_01", "Ab_Hair_R3_01", "Ab_Hair_R4_01" } } },
    weapon = P .. "Weapon/Sword/CH_W_Sword_02/CH_W_Sword_02.CH_W_Sword_02" },
  scarlet = { label = "Scarlet", body = "/Game/DLC_2/Art/Character/Monster/CH_M_NA_961/CH_M_NA_961.CH_M_NA_961",
    face = "/Game/DLC_2/Art/Character/Monster/CH_M_NA_961/CH_M_NA_961_Facial.CH_M_NA_961_Facial",
    hide = { hair = true }, dlc = true, hideMats = { 3, 4, 5 },
    hair = { mesh = "/Game/DLC_2/Art/Character/PC/00_HR/EVE_HR_Nikke_01/EVE_HR_Nikke_01.EVE_HR_Nikke_01",
      anim = "/Game/DLC_2/Art/Character/PC/00_HR/EVE_HR_Nikke_01/EVE_HR_Nikke_01_AnimBP.EVE_HR_Nikke_01_AnimBP_C" },
    weapon = "/Game/DLC_2/Art/Character/Monster/CH_M_NA_961/CH_M_NA_961_Weapon_01.CH_M_NA_961_Weapon_01",
    weaponTurn = { Pitch = 90, Yaw = 0, Roll = 0 },
    post = "/Game/DLC_2/Art/Character/PC/CH_P_EVE_Nikke_01/CH_P_EVE_Nikke_01.CH_P_EVE_Nikke_01" },
  raven = { label = "Raven", body = P .. "PC/CH_P_EVE_11/CH_P_EVE_11.CH_P_EVE_11", hide = { hair = true },
    face = P .. "Monster/CH_M_NA_53/CH_M_NA_53_Facial.CH_M_NA_53_Facial",
    extras = { { path = P .. "Monster/CH_M_NA_53/CH_M_NA_53_Hair.CH_M_NA_53_Hair", head = true, sim = { "HBn_Root" }, collide = true,
      prefix = "HB", on = "HBN_LMA02", tips = { "HBN_LMA09", "HBN_RMA09", "HBN_LME11", "HBN_RMC11" },
      damp = { 3, 14 }, blend = 0.8 } },
    weapon = P .. "Monster/CH_M_NA_53/CH_M_NA_53_Weapon.CH_M_NA_53_Weapon" },
}
-- her mesh slots (MeshInfoList's MeshSlot, ESBSkelMeshSlot): the face, the hair ones (Hair1, Ponytail, PonytailShort)
-- and her outfit's accessories (Accessory1-5: Eve's, hidden on the others)
M.FACE, M.HAIR1, M.HAIR, M.ACC = 1, 2, { [2] = true, [3] = true, [4] = true }, { [9] = true, [10] = true, [11] = true, [12] = true, [13] = true }
-- her weapon slots (Weapon1-4), and her drawn sword's mesh in them
M.WEAPON, M.SWORD = { [5] = true, [6] = true, [7] = true, [8] = true }, "CH_W_Sword_01"
-- her hairpin (a component on SC_HairACC, not in her slots)
M.PIN = "CH_ACC_HairPin"
-- her main bones: one simulated while she is up is a part of her off (the gore mod's cuts), nothing swapped then
M.MAIN = { "Bip001-Head", "Bip001-Neck", "Bip001-Spine", "Bip001-Spine1", "Bip001-Spine2", "Bip001-L-Clavicle",
  "Bip001-L-UpperArm", "Bip001-L-Forearm", "Bip001-L-Hand", "Bip001-R-Clavicle", "Bip001-R-UpperArm", "Bip001-R-Forearm",
  "Bip001-R-Hand", "Bip001-L-Thigh", "Bip001-L-Calf", "Bip001-L-Foot", "Bip001-R-Thigh", "Bip001-R-Calf", "Bip001-R-Foot" }
-- Raven's hair (and Tachy's, swung by M.SPRING instead) at Eve's head: its reference pose's head on hers (its strands hang as made), the strands
-- under sim (an extra's sim, its bones named prefix...) simulated on its own physics asset (a body per strand bone),
-- each joint driven back to the made shape (settings.hairSpring, hairDamping) so it swings and settles. A strand's tip
-- (tips) further than FAR_CM from her head (a teleport, a blow-up) is put back (simulation off, on again a second
-- later). Raven's asset damps the lower half of each long strand at linear 5, angular 30 and the upper at 1, 5: on Eve
-- the lower hung still while the front swung (playtest), at 1, 5 throughout they swung too wildly, and at 2, 12 still
-- flew about like a ragdoll's and leapt off her suit, at 4, 24 with 0.6 of the swing shown they looked stiff, at times
-- still (playtests). An extra's damp ({ linear, angular }) is what each strand body is made with (none: the asset's
-- own), the asset given its own values back after; its blend is how much of the simulated pose shows over the made
-- shape (1 all of it): Raven's at 3, 14 and 0.8. Each frame (M.frame) a strand found stopped is simulated again at once
-- (Tachy's, simulated so, stopped on nearly every frame, playtests), what it lost put back first (strands_mend), and
-- what it looked like and how often it stops is logged
M.STRANDS = { SPRING = 3000, DAMPING = 100, FAR_CM = 250, HAIR_CH = 6, BODY_CH = 7 }
-- Raven's strands touch her body only: capsules on her bones (BODY_CAPS, fitted to CH_P_EVE_11 in its reference
-- pose: her hips and back across, her thighs and calves along, a ball on each breast, on its own bone so it follows
-- the jiggle: her front strands went through them, playtest), physics only, of a channel nothing else of hers uses
-- (Destructible, BODY_CH), blocking only her hair's (Vehicle, HAIR_CH), her hair blocking only theirs: the strands
-- went through her (playtest), and touching her body's own bodies they would push her about. Each: its bone, radius,
-- half height, at and q its place on the bone
M.BODY_CAPS = {
  { bone = "Bip001-Pelvis", r = 10.6, h = 19.8, at = { 1.36, 5.37, -2.94 }, q = { 0, 0.7071, 0, -0.7071 } },
  { bone = "Bip001-Pelvis", r = 9.4, h = 17.9, at = { -0.11, -3.63, -2.15 }, q = { 0, 0.7071, 0, -0.7071 } },
  { bone = "Bip001-Spine", r = 8.9, h = 15.2, at = { -0.55, -1.27, -0.10 }, q = { 0.0263, -0.7066, -0.0263, 0.7066 } },
  { bone = "Bip001-Spine1", r = 9.4, h = 23.9, at = { -0.03, -0.74, 1.40 }, q = { 0.0307, 0.7064, -0.0307, -0.7064 } },
  { bone = "Bip001-Spine2", r = 11.2, h = 11.2, at = { 0.00, -0.71, 2.02 }, q = { -0.0454, -0.7056, 0.0454, 0.7056 } },
  { bone = "Bip001-Spine2", r = 9.5, h = 9.7, at = { 0.74, -9.92, 0.98 }, q = { -0.0454, -0.7056, 0.0454, 0.7056 } },
  { bone = "Bip001-L-Thigh", r = 6.2, h = 22.4, at = { 1.31, -22.38, -1.13 }, q = { -0.1046, -0.6993, 0.6993, -0.1046 } },
  { bone = "Bip001-L-Calf", r = 3.5, h = 19.8, at = { -0.33, -19.78, -1.63 }, q = { -0.0292, 0.7065, -0.7065, -0.0292 } },
  { bone = "Bip001-R-Thigh", r = 5.9, h = 22.4, at = { 0.12, -22.38, 0.71 }, q = { -0.6993, -0.1047, 0.1047, -0.6993 } },
  { bone = "Bip001-R-Calf", r = 3.5, h = 19.8, at = { 0.33, -19.78, -1.63 }, q = { 0.7065, -0.0292, 0.0292, 0.7065 } },
  { bone = "Ab-L-Breast", r = 6.5, h = 6.5, at = { -1.12, -6.55, -0.31 }, q = { 0, 0, 0, 1 } },
  { bone = "Ab-R-Breast", r = 6.5, h = 6.5, at = { 0.88, 6.55, 0.35 }, q = { 0, 0, 0, 1 } },
}

-- her sword folded into her hairpin: the same component moved to SC_SwordingPoint, a socket on her head bone; drawn
-- it rides Weapon (on Bip001-Prop1, which her hands hold: the skeleton's sockets). Another's blade doesn't fold, so it
-- is hidden while the socket it rides is on a head bone (of what it hangs on: the gore mod's photo mode moves a
-- cut-off head and what rides it onto a copy of her mesh), shown on any other, and hidden again each frame a scene
-- showed it (it stood in her hair after a cutscene, playtest). (It was told by its distance from her head before: a
-- swing past her head hid the drawn blade, playtest.) A socket that isn't on what it hangs on: by that distance,
-- hidden under PIN_IN_CM, shown past PIN_OUT_CM
M.PIN_IN_CM, M.PIN_OUT_CM = 40, 60
M.HEAD = "Bip001-Head"

local st = { pawn = nil, who = "eve", blade = true, was = nil, next = 0, failed = {}, found = {}, blades = {}, pinned = {},
  extras = {}, pins = {}, sockets = {}, ours = {}, oursMesh = {}, turns = {}, settle = {}, mats = nil, hairOn = nil }

function M.init(c)
  ctx, try, valid = c, c.try, c.valid
end

local function addr(o) return valid(o) and try(function() return o:GetAddress() end) or nil end
local function asset(path)
  local a = try(function() return StaticFindObject(path) end)
  if not valid(a) and LoadAsset and (not ctx.may_load or ctx.may_load()) then a = try(function() return LoadAsset(path) end) end
  return valid(a) and a or nil
end
local function mesh_name(c)
  local m = try(function() return c.SkeletalMesh end)
  return valid(m) and try(function() return m:GetFName():ToString() end) or nil
end
-- her slots; face: her face's (ESBMesh_Face, or another slot holding a mesh named like a face, Face or Facial
-- (Raven's): in game it is in Etc1, 14)
local function slots(pawn)
  local out = {}
  try(function() pawn.MeshInfoList:ForEach(function(_, e)
    local info = e:get()
    local c = info.MeshComponent
    if valid(c) then
      local n = mesh_name(c)
      out[#out + 1] = { slot = info.MeshSlot, comp = c,
        face = info.MeshSlot == M.FACE or (n ~= nil and n:find("Fac[ei]") ~= nil and not M.WEAPON[info.MeshSlot]) }
    end
  end) end)
  return out
end

-- what she wore before (put back by "eve"): her body's and face's meshes, the components it hid
local function remember(pawn, mesh)
  if st.was and st.was.pawn == addr(pawn) then return end
  local face
  for _, s in ipairs(slots(pawn)) do if s.face and not face then face = s.comp end end
  st.was = { pawn = addr(pawn), body = try(function() return mesh.SkeletalMesh end),
    face = face, faceMesh = face and try(function() return face.SkeletalMesh end), hidden = {}, weapons = {}, mats = {} }
end

-- a mesh's own materials, by slot (0-based)
local function own_mats(m)
  local out, i = {}, 0
  try(function() m.Materials:ForEach(function(_, e) out[i] = try(function() return e:get().MaterialInterface end); i = i + 1 end) end)
  return out
end
local function addrs(l) local s = {} for _, x in pairs(l) do local a = addr(x); if a then s[a] = true end end return s end
-- a material of one of the looks' meshes, or an instance the game made of one (its parents), and not one of keep (the
-- materials of the mesh going back on: Raven's suit is an outfit of Eve's too)
local function ours(mt, keep)
  for _ = 1, 6 do
    local a = addr(mt)
    if not a then return false end
    if keep and keep[a] then return false end
    if st.ours[a] then return true end
    mt = try(function() return mt.Parent end)
  end
  return false
end
-- a mesh on one of her components with that mesh's own materials: what the game set on the component for Eve's
-- (her outfit's material instances) stayed on by slot number, on the other's parts it showed wrong or glowing.
-- What was on it first (its mesh and materials) is kept for restore
local function wear(c, m)
  local a = addr(c)
  local own = own_mats(m)
  for _, mi in pairs(own) do local k = addr(mi); if k then st.ours[k] = true end end
  if addr(m) then st.oursMesh[addr(m)] = true end
  if a and not st.was.mats[a] then
    local n = try(function() return c:GetNumMaterials() end) or 0
    local was = {}
    for i = 0, n - 1 do was[i] = try(function() return c:GetMaterial(i) end) end
    st.was.mats[a] = { comp = c, mats = was, n = n, mesh = try(function() return c.SkeletalMesh end) }
  end
  try(function() c:SetSkeletalMesh(m, true) end)
  for k, mi in pairs(own) do if valid(mi) then try(function() c:SetMaterial(k, mi) end) end end
end
-- the game put a mesh of its own on c over ours (another outfit: the outfit menu, a shield-break outfit mod): it and
-- the materials the game gave it are what she wears now, kept for restore. A slot still holding one of ours (the game
-- left it, or made an instance of it) takes the material kept for that slot if the mesh is the one kept, else the new
-- mesh's own: the kept ones are another mesh's by slot number (back to Eve, her outfit wore the first one's, playtest)
local function regear(c, cur)
  local w = st.was.mats[addr(c)]
  local n = try(function() return c:GetNumMaterials() end) or 0
  local own = own_mats(cur)
  local keep = addrs(own)
  local same = w and addr(w.mesh) == addr(cur)
  local mats = {}
  for k = 0, n - 1 do
    local mt = try(function() return c:GetMaterial(k) end)
    if ours(mt, keep) then
      mt = same and valid(w.mats[k]) and not ours(w.mats[k], keep) and w.mats[k] or own[k]
    end
    mats[k] = mt
  end
  st.was.mats[addr(c)] = { comp = c, mats = mats, n = n, mesh = cur }
  return cur
end
-- m back on c with its materials: the ones kept, any of ours among them (an instance the game made of one, or the
-- game's own mesh put on over ours) its own instead
local function unwear(c, m)
  try(function() c:SetSkeletalMesh(m, true) end)
  local w = st.was and st.was.mats[addr(c)]
  if not w then return end
  local own = own_mats(m)
  local keep = addrs(own)
  local n = math.max(w.n, try(function() return c:GetNumMaterials() end) or 0)
  for i = 0, n - 1 do
    local mt = w.mats[i]
    if not valid(mt) or ours(mt, keep) then mt = own[i] end
    if valid(mt) then try(function() c:SetMaterial(i, mt) end) end
  end
  st.settle[#st.settle + 1] = { comp = c, mesh = m, keep = keep, own = own }
end
-- for a few seconds after "eve": a slot the game set to one of ours again (its instances of them, kept) its mesh's own
local function settle()
  if #st.settle == 0 then return end
  st.settleTicks = (st.settleTicks or 0) + 1
  for _, s in ipairs(st.settle) do
    -- (a look's own mesh on it again after "eve": hers put back. Back to Eve she still wore Raven's suit, playtest)
    local cur = valid(s.comp) and try(function() return s.comp.SkeletalMesh end)
    if valid(cur) and addr(cur) ~= addr(s.mesh) and st.oursMesh[addr(cur)] and valid(s.mesh) then
      try(function() s.comp:SetSkeletalMesh(s.mesh, true) end)
      for i, mi in pairs(s.own) do if valid(mi) then try(function() s.comp:SetMaterial(i, mi) end) end end
      log(string.format("the last look's %s on her again: her own %s put back", tostring(try(function() return cur:GetFName():ToString() end)),
        tostring(try(function() return s.mesh:GetFName():ToString() end))))
    end
    if valid(s.comp) and addr(try(function() return s.comp.SkeletalMesh end)) == addr(s.mesh) then
      local n = try(function() return s.comp:GetNumMaterials() end) or 0
      for i = 0, n - 1 do
        local mt = try(function() return s.comp:GetMaterial(i) end)
        if ours(mt, s.keep) and valid(s.own[i]) then
          try(function() s.comp:SetMaterial(i, s.own[i]) end)
          if not s.said then log(string.format("a material of the last look on her again (slot %d): her own put back", i)) end
          s.said = true
        end
      end
    end
  end
  if st.settleTicks >= 10 then st.settle, st.settleTicks = {}, nil end
end

local function hide(c, body)
  if not valid(c) or addr(c) == addr(body) then return end
  if try(function() return c:IsVisible() end) ~= true then return end
  try(function() c:SetVisibility(false, false) end)
  st.was.hidden[#st.was.hidden + 1] = c
end

local tighten, body_caps, spring_init -- (below)
local function drop_extras()
  for _, x in pairs(st.extras) do tighten(x) end
  for _, x in pairs(st.extras) do
    for _, c in ipairs(x.caps or {}) do if valid(c) then try(function() c:K2_DestroyComponent(c) end) end end
    if valid(x.comp) then try(function() x.comp:K2_DestroyComponent(x.comp) end) end
  end
  st.extras = {}
end

-- v turned by the quaternion q
local function qrot(q, v)
  local x, y, z, w = q.X, q.Y, q.Z, q.W
  local tx, ty, tz = 2 * (y * v.Z - z * v.Y), 2 * (z * v.X - x * v.Z), 2 * (x * v.Y - y * v.X)
  return { X = v.X + w * tx + (y * tz - z * ty), Y = v.Y + w * ty + (z * tx - x * tz), Z = v.Z + w * tz + (x * ty - y * tx) }
end
-- the transform undoing t (a bone's in its component, unit scale)
function M.inverse(t)
  local q = { X = -t.Rotation.X, Y = -t.Rotation.Y, Z = -t.Rotation.Z, W = t.Rotation.W }
  local p = qrot(q, t.Translation)
  return { Rotation = q, Translation = { X = -p.X, Y = -p.Y, Z = -p.Z }, Scale3D = { X = 1, Y = 1, Z = 1 } }
end
local function vec_of(f) return try(function() local v = f(); return { X = v.X, Y = v.Y, Z = v.Z } end) end
local function hair_sim(x, on)
  local c, set = x.comp, cfg()
  if on then x.simAt = os.clock() end
  for _, r in ipairs(x.sim) do try(function() c:SetAllBodiesBelowSimulatePhysics(FName(r), on, false) end) end
  if on and x.blend then
    for _, r in ipairs(x.sim) do try(function() c:SetAllBodiesBelowPhysicsBlendWeight(FName(r), x.blend, false, false) end) end
  end
  if on then
    try(function() c:SetAllMotorsAngularPositionDrive(true, true, false) end)
    try(function() c:SetAllMotorsAngularDriveParams(tonumber(set.hairSpring) or M.STRANDS.SPRING,
      tonumber(set.hairDamping) or M.STRANDS.DAMPING, 0, false) end)
  end
end
-- the strands' bodies in pa (bones named prefix...) damped at damp's. What each had kept, for tighten
local function loosen(pa, prefix, damp)
  local back = {}
  if not damp then return back end
  local up = prefix:upper()
  try(function() pa.SkeletalBodySetups:ForEach(function(_, e)
    local bs = e:get()
    local n = try(function() return bs.BoneName:ToString() end) or ""
    if n:upper():sub(1, #up) == up then
      local l = try(function() return bs.DefaultInstance.LinearDamping end)
      local a = try(function() return bs.DefaultInstance.AngularDamping end)
      if l and a and (l ~= damp[1] or a ~= damp[2]) then
        back[#back + 1] = { bs = bs, l = l, a = a }
        try(function() bs.DefaultInstance.LinearDamping = damp[1] end)
        try(function() bs.DefaultInstance.AngularDamping = damp[2] end)
      end
    end
  end) end)
  return back
end
-- the asset's own values back (the boss uses it too); its bodies on her hair were made already
tighten = function(x)
  for _, b in ipairs(x.loose or {}) do
    if valid(b.bs) then
      try(function() b.bs.DefaultInstance.LinearDamping = b.l end)
      try(function() b.bs.DefaultInstance.AngularDamping = b.a end)
    end
  end
  x.loose = nil
end
-- her body's capsules for the hair to touch (M.BODY_CAPS), on her mesh's bones
body_caps = function(pawn, mesh)
  local out = {}
  local cls = try(function() return StaticFindObject("/Script/Engine.CapsuleComponent") end)
  if not (valid(cls) and valid(pawn)) then return out end
  for _, b in ipairs(M.BODY_CAPS) do
    local c = try(function()
      return pawn:AddComponentByClass(cls, true, { Rotation = { X = 0, Y = 0, Z = 0, W = 1 },
        Translation = { X = 0, Y = 0, Z = 0 }, Scale3D = { X = 1, Y = 1, Z = 1 } }, false)
    end)
    if valid(c) then
      try(function() c:SetCapsuleSize(b.r, b.h, false) end)
      try(function() c:SetGenerateOverlapEvents(false) end)
      try(function() c:SetCollisionObjectType(M.STRANDS.BODY_CH) end)
      try(function() c:SetCollisionResponseToAllChannels(0) end)
      try(function() c:SetCollisionResponseToChannel(M.STRANDS.HAIR_CH, 2) end)
      try(function() c:SetCollisionEnabled(2) end)
      try(function() c:SetHiddenInGame(true, false) end)
      try(function() c:K2_AttachToComponent(mesh, FName(b.bone), 2, 2, 2, false) end)
      try(function() c:K2_SetRelativeTransform({ Rotation = { X = b.q[1], Y = b.q[2], Z = b.q[3], W = b.q[4] },
        Translation = { X = b.at[1], Y = b.at[2], Z = b.at[3] }, Scale3D = { X = 1, Y = 1, Z = 1 } }, false, {}, true) end)
      out[#out + 1] = c
    end
  end
  return out
end
-- Tachy's strands swung in Lua (x.spring: the strands' roots), each bone a point: it lags behind the head, falls a
-- little (G), is pulled back toward where the made shape puts it from the bone above (STIFF a 60th of a second),
-- keeps its length, and is pushed out of balls on her neck and chest (BALLS: her mesh's bones), the bones turned to
-- point along. Physics never held: her strands' bodies, on Eve's mesh, on a copy at her head, on an actor of its own,
-- stopped on nearly every frame with nothing of them lost (playtests), by something of the game's. A jump of more than
-- JUMP_CM in a frame (a teleport) puts them back as made
M.SPRING = { STIFF = 0.12, DAMP = 0.1, G = -400, JUMP_CM = 100,
  BALLS = { { bone = "Bip001-Neck", r = 5.5 }, { bone = "Bip001-Spine2", r = 11 } } }
local function v3(a) return { X = a.X, Y = a.Y, Z = a.Z } end
local function vadd(a, b) return { X = a.X + b.X, Y = a.Y + b.Y, Z = a.Z + b.Z } end
local function vsub(a, b) return { X = a.X - b.X, Y = a.Y - b.Y, Z = a.Z - b.Z } end
local function vmul(a, k) return { X = a.X * k, Y = a.Y * k, Z = a.Z * k } end
local function vlen(a) return math.sqrt(a.X * a.X + a.Y * a.Y + a.Z * a.Z) end
local function qmul(a, b)
  return { X = a.W * b.X + a.X * b.W + a.Y * b.Z - a.Z * b.Y, Y = a.W * b.Y - a.X * b.Z + a.Y * b.W + a.Z * b.X,
    Z = a.W * b.Z + a.X * b.Y - a.Y * b.X + a.Z * b.W, W = a.W * b.W - a.X * b.X - a.Y * b.Y - a.Z * b.Z }
end
-- the shortest turn taking direction a onto b
local function qfrom(a, b)
  local la, lb = vlen(a), vlen(b)
  if la < 1e-6 or lb < 1e-6 then return { X = 0, Y = 0, Z = 0, W = 1 } end
  a, b = vmul(a, 1 / la), vmul(b, 1 / lb)
  local d = a.X * b.X + a.Y * b.Y + a.Z * b.Z
  if d < -0.9999 then return { X = 0, Y = 0, Z = 1, W = 0 } end
  local q = { X = a.Y * b.Z - a.Z * b.Y, Y = a.Z * b.X - a.X * b.Z, Z = a.X * b.Y - a.Y * b.X, W = 1 + d }
  local l = math.sqrt(q.X ^ 2 + q.Y ^ 2 + q.Z ^ 2 + q.W ^ 2)
  return { X = q.X / l, Y = q.Y / l, Z = q.Z / l, W = q.W / l }
end
-- its strand bones (the roots' and under them, parents first), each made place and turn in the component
spring_init = function(x)
  local c, out, at = x.comp, {}, {}
  local n = try(function() return c:GetNumBones() end) or 0
  local roots = {}
  for _, r in ipairs(x.spring) do roots[r] = true end
  local parent, depth = {}, {}
  for i = 0, n - 1 do
    local b = try(function() return c:GetBoneName(i):ToString() end)
    local p = b and try(function() return c:GetParentBone(FName(b)):ToString() end)
    if b then parent[b] = p end
  end
  local function root_of(b)
    local d = 0
    while b and d < 32 do
      if roots[b] then return b, d end
      b, d = parent[b], d + 1
    end
  end
  for b in pairs(parent) do
    local r, d = root_of(b)
    if r then
      local t = try(function()
        local v = c:GetBoneTransformByName(FName(b), 1)
        return { q = { X = v.Rotation.X, Y = v.Rotation.Y, Z = v.Rotation.Z, W = v.Rotation.W }, p = v3(v.Translation) }
      end)
      if t then
        local e = { name = b, root = b == r, depth = d, q = t.q, p = t.p, parent = b ~= r and parent[b] or nil }
        out[#out + 1] = e
        at[b] = e
      end
    end
  end
  table.sort(out, function(a, b) return a.depth < b.depth or (a.depth == b.depth and a.name < b.name) end)
  for _, e in ipairs(out) do
    local p = e.parent and at[e.parent]
    if p then
      e.up = p
      e.len = vlen(vsub(e.p, p.p))
      p.kid = p.kid or e
    end
  end
  x.bones, x.pts = out, nil
  return #out
end
-- the component's place in the world
local function world_of(c)
  return try(function()
    local t = c:K2_GetComponentToWorld()
    return { q = { X = t.Rotation.X, Y = t.Rotation.Y, Z = t.Rotation.Z, W = t.Rotation.W }, p = v3(t.Translation) }
  end)
end
local function spring_frame(x, mesh)
  local c, S = x.comp, M.SPRING
  if not (x.bones and #x.bones > 0) then return end
  local C = world_of(c)
  if not C then return end
  local now = os.clock()
  local dt = math.min(math.max(now - (x.springAt or now), 1 / 240), 1 / 30)
  x.springAt = now
  local function made(e) return vadd(qrot(C.q, e.p), C.p) end
  local first = not x.pts
  if not first then
    local r = x.bones[1]
    if vlen(vsub(made(r), x.pts[r.name].p)) > S.JUMP_CM then first = true end
  end
  if first then
    x.pts = {}
    for _, e in ipairs(x.bones) do local w = made(e); x.pts[e.name] = { p = w, was = w } end
  end
  local balls = {}
  for _, b in ipairs(S.BALLS) do
    local p = try(function() return v3(mesh:GetSocketLocation(FName(b.bone))) end)
    if p then balls[#balls + 1] = { p = p, r = b.r } end
  end
  local k = 1 - (1 - S.STIFF) ^ (dt * 60)
  local keep = (1 - S.DAMP) ^ (dt * 60)
  for _, e in ipairs(x.bones) do
    local pt = x.pts[e.name]
    if not e.up then
      pt.was, pt.p = pt.p, made(e)
    else
      local up = x.pts[e.up.name].p
      local p = vadd(vadd(pt.p, vmul(vsub(pt.p, pt.was), keep)), { X = 0, Y = 0, Z = S.G * dt * dt })
      local goal = vadd(up, qrot(C.q, vsub(e.p, e.up.p)))
      p = vadd(p, vmul(vsub(goal, p), k))
      for _, b in ipairs(balls) do
        local d = vsub(p, b.p)
        local l = vlen(d)
        if l < b.r and l > 1e-4 then p = vadd(b.p, vmul(d, b.r / l)) end
      end
      local d = vsub(p, up)
      local l = vlen(d)
      if l > 1e-4 then p = vadd(up, vmul(d, e.len / l)) end
      pt.was, pt.p = pt.p, p
    end
  end
  -- (each bone turned so its made direction to the bone below points at that bone now; a tip as the bone above it)
  for _, e in ipairs(x.bones) do
    local made_q = qmul(C.q, e.q)
    local turn
    if e.kid then
      turn = qfrom(qrot(C.q, vsub(e.kid.p, e.p)), vsub(x.pts[e.kid.name].p, x.pts[e.name].p))
    else
      turn = e.up and x.pts[e.up.name].turn or { X = 0, Y = 0, Z = 0, W = 1 }
    end
    x.pts[e.name].turn = turn
    local q = qmul(turn, made_q)
    local p = x.pts[e.name].p
    try(function() c:SetBoneTransformByName(FName(e.name), { Rotation = q, Translation = p, Scale3D = { X = 1, Y = 1, Z = 1 } }, 0) end)
  end
end

-- a mesh at her head (x.head): attached to her head bone, its own head's reference pose undone so the two heads are
-- one; its bones posed only once it is registered (the next second), hidden till then
local function place_on_head(x, mesh)
  local c = x.comp
  local t = try(function()
    local r = c:GetSocketTransform(FName("Bip001-Head"), 2)
    return { Rotation = { X = r.Rotation.X, Y = r.Rotation.Y, Z = r.Rotation.Z, W = r.Rotation.W },
      Translation = { X = r.Translation.X, Y = r.Translation.Y, Z = r.Translation.Z } }
  end)
  local tr = t and t.Translation
  if not tr or math.sqrt(tr.X ^ 2 + tr.Y ^ 2 + tr.Z ^ 2) < 50 then return false end
  try(function() c:K2_SetRelativeTransform(M.inverse(t), false, {}, true) end)
  try(function() c:SetVisibility(true, false) end)
  x.placed = true
  if x.sim then
    local pa = try(function() return c.SkeletalMesh.PhysicsAsset end)
    if valid(pa) then
      x.pa = pa
      x.loose = loosen(pa, x.prefix, x.damp)
      try(function() c:SetPhysicsAsset(pa, true) end)
      for _, b in ipairs(x.term or {}) do try(function() c:TermBodiesBelow(FName(b)) end) end
    end
    hair_sim(x, true)
    if x.collide then x.caps = body_caps(st.pawn, mesh) end
    log(string.format("%s: at her head, its strands simulated (%s), %s%s", x.name,
      try(function() return c:IsSimulatingPhysics(FName(x.on)) end) == true and "on" or "NOT on: hangs as made",
      x.damp and string.format("%d of its bodies damped at %g, %g", x.loose and #x.loose or 0, x.damp[1], x.damp[2])
        or "its asset's own damping", x.blend and string.format(", %d%% of their swing shown", math.floor(x.blend * 100 + 0.5)) or "",
      x.caps and string.format(", touching %d capsules on her body", #x.caps) or ""))
  end
  if x.spring then
    local n = spring_init(x)
    log(string.format("%s: at her head, %s", x.name, n > 0 and string.format("%d strand bones swung by spring", n)
      or "its bones NOT found: hangs as made"))
  end
  return true
end
-- each second: its strands simulating, near her head (else put back)
local function hair_watch(x)
  local c = x.comp
  if not (x.sim and x.placed) then return end
  if x.loose then tighten(x) end
  if try(function() return c:GetCollisionEnabled() end) ~= 2 then return end -- (another mod's query only for a moment)
  if x.off then x.off = nil; hair_sim(x, true); return end
  if try(function() return c:IsSimulatingPhysics(FName(x.on)) end) ~= true then
    hair_sim(x, true)
    x.restarts = (x.restarts or 0) + 1
    if x.restarts <= 3 then log(x.name .. ": its strands stopped (something turned them off): simulated again") end
    return
  end
  local h = vec_of(function() return c:GetSocketLocation(FName("Bip001-Head")) end)
  if not h then return end
  for _, b in ipairs(x.tips) do
    local p = vec_of(function() return c:GetSocketLocation(FName(b)) end)
    local d = p and math.sqrt((p.X - h.X) ^ 2 + (p.Y - h.Y) ^ 2 + (p.Z - h.Z) ^ 2)
    if d and (d > M.STRANDS.FAR_CM or d ~= d) then
      hair_sim(x, false)
      x.off = true
      x.resets = (x.resets or 0) + 1
      if x.resets <= 3 then log(string.format("%s: %s %.0f cm from her head: put back as made", x.name, b, d)) end
      return
    end
  end
end

-- material sections (0-based ids, as each section's material in these meshes) hidden on every LOD of c's mesh, or
-- all shown again (ids nil). True once the first is hidden. (The engine's call is (id, section, show, lod), an older
-- one's (id, show, lod): the second asked when the first left it shown)
local function sections(c, ids, show)
  local n = math.max(1, try(function() return c:GetNumLODs() end) or 1)
  for lod = 0, n - 1 do
    if not ids then try(function() c:ShowAllMaterialSections(lod) end)
    else
      for _, id in ipairs(ids) do
        try(function() c:ShowMaterialSection(id, id, show, lod) end)
        if try(function() return c:IsMaterialSectionShown(id, lod) end) ~= (show == true) then
          try(function() c:ShowMaterialSection(id, show, lod) end)
        end
      end
    end
  end
  return ids and try(function() return c:IsMaterialSectionShown(ids[1], 0) end) == false
end
local function hidden_mats(c, ids) return try(function() return c:IsMaterialSectionShown(ids[1], 0) end) == false end
-- her hair component (Hair1) with another's hair for Eve (look.hair: its mesh, its AnimBP): what was on it kept for
-- restore (a hair the game put on over it since: that one), shown though Eve's other hair is hidden
local function put_hair(c, h, out)
  local m = asset(h.mesh)
  if not m then return end
  local cur = try(function() return c.SkeletalMesh end)
  if addr(cur) == addr(m) then return end
  if st.was.mats[addr(c)] and valid(cur) then
    regear(c, cur)
    out[#out + 1] = "(the game put " .. tostring(try(function() return cur:GetFName():ToString() end)) .. " on her hair: hers for Eve)"
  end
  local vis = st.was.hair and st.was.hair.vis
  if vis == nil then vis = try(function() return c:IsVisible() end) == true end
  st.was.hair = { comp = c, cls = try(function() return c.AnimClass end), vis = vis }
  wear(c, m)
  -- (its AnimBP loaded with the mesh, its post process)
  local cls = asset(h.anim)
  if cls then try(function() c:SetAnimInstanceClass(cls) end) end
  if try(function() return c:IsVisible() end) ~= true then try(function() c:SetVisibility(true, false) end) end
  out[#out + 1] = "hair " .. h.mesh:match("([^/.]+)$") .. (cls and "" or " (its AnimBP NOT found: it won't move)")
end

-- her body's mesh with another mesh's post process AnimBP (look.post: that mesh), the one it had kept for post_off.
-- Set on the mesh asset (a component takes its mesh's as the mesh goes on) only while the mesh goes on her
local function post_on(body, look, out)
  if not look.post then return end
  local from = asset(look.post)
  local cls = from and try(function() return from.PostProcessAnimBlueprint end)
  if not valid(cls) then cls = nil end
  local was = try(function() return body.PostProcessAnimBlueprint end)
  if cls then try(function() body.PostProcessAnimBlueprint = cls end) end
  local ok = cls and addr(try(function() return body.PostProcessAnimBlueprint end)) == addr(cls)
  if ok then st.post = { mesh = body, was = was } end
  out[#out + 1] = (ok and "its post process " or "its post process NOT set (" .. (cls and "not taken" or "not found") .. ") ")
    .. look.post:match("([^/.]+)$")
end
-- the mesh's own post process back (the boss wears it too)
local function post_off()
  local p = st.post
  st.post = nil
  if p and valid(p.mesh) then try(function() p.mesh.PostProcessAnimBlueprint = p.was end) end
end

-- the look on her (again: anything the game put back). Returns a line for the log, or nil when all was in place
local function apply(pawn, mesh, look)
  local out = {}
  local body = asset(look.body)
  if not body then
    -- (not loaded now, the level loading: next second)
    if ctx.may_load and not ctx.may_load() then return nil end
    if not st.failed[look.body] then
      st.failed[look.body] = true
      log(string.format("%s: %s not found%s; she stays as she is", look.label, look.body, look.dlc and " (needs its DLC)" or ""))
    end
    return nil
  end
  -- (a mesh the game put on her since: her outfit now, put back for Eve. A new Eve is first seen with her
  -- Blueprint's own mesh, and the game puts her outfit on a second later; kept from the first look, back to Eve she
  -- wore CH_P_EVE_11, playtest)
  local fresh = not (st.was and st.was.pawn == addr(pawn))
  remember(pawn, mesh)
  local cur = try(function() return mesh.SkeletalMesh end)
  if addr(cur) ~= addr(body) then
    if not fresh and valid(cur) then
      st.was.body = regear(mesh, cur)
      out[#out + 1] = "(the game put " .. tostring(try(function() return cur:GetFName():ToString() end)) .. " on her: hers for Eve)"
    end
    post_on(body, look, out)
    wear(mesh, body)
    -- (off the asset again at once: her component made its post process as the mesh went on, and a copy of her mesh
    -- made after, the gore mod's for a cut-off head in photo mode, ran it too and the game froze, playtest)
    post_off()
    out[#out + 1] = "body " .. look.body:match("([^/.]+)$")
  end
  -- (her own hair's sections on her body hidden: again once the game's mesh came and went)
  if look.hideMats and not hidden_mats(mesh, look.hideMats) then
    local ok = sections(mesh, look.hideMats, false)
    out[#out + 1] = (ok and "its hair's sections hidden (" or "its hair's sections NOT hidden (") .. table.concat(look.hideMats, ", ") .. ")"
  end
  for _, s in ipairs(slots(pawn)) do
    if s.face then
      if look.hide.face then hide(s.comp, mesh)
      elseif look.face then
        local f = asset(look.face)
        local fc = try(function() return s.comp.SkeletalMesh end)
        if f and addr(fc) ~= addr(f) then
          if not fresh and valid(fc) and addr(s.comp) == addr(st.was.face) then st.was.faceMesh = regear(s.comp, fc) end
          wear(s.comp, f)
          out[#out + 1] = "face " .. look.face:match("([^/.]+)$")
        end
      end
    elseif s.slot == M.HAIR1 and look.hair then
      put_hair(s.comp, look.hair, out)
    elseif M.HAIR[s.slot] and look.hide.hair or M.ACC[s.slot] then
      hide(s.comp, mesh)
    elseif M.WEAPON[s.slot] and look.weapon and cfg().blade ~= false then
      local cur = try(function() return s.comp.SkeletalMesh end)
      local nm = valid(cur) and try(function() return cur:GetFName():ToString() end)
      local w = nm == M.SWORD and asset(look.weapon)
      if w then
        local rot = try(function() local r = s.comp.RelativeRotation; return { Pitch = r.Pitch, Yaw = r.Yaw, Roll = r.Roll } end)
        st.was.weapons[#st.was.weapons + 1] = { comp = s.comp, mesh = cur, ours = w, rot = look.weaponTurn and rot }
        wear(s.comp, w)
        if look.weaponTurn then
          st.turns[addr(s.comp)] = { comp = s.comp, mesh = w, rot = look.weaponTurn }
          try(function() s.comp:K2_SetRelativeRotation(look.weaponTurn, false, {}, true) end)
        end
        out[#out + 1] = "blade " .. look.weapon:match("([^/.]+)$")
      end
    end
  end
  -- her hairpin hidden (each frame too: M.frame)
  try(function() mesh.AttachChildren:ForEach(function(_, e)
    local c = e:get()
    if valid(c) and mesh_name(c) == M.PIN and not st.pins[addr(c)] then
      st.pins[addr(c)] = c
      st.was.pins = st.was.pins or {}
      st.was.pins[#st.was.pins + 1] = { comp = c, hid = try(function() return c.bHiddenInGame end) == true }
      try(function() c:SetHiddenInGame(true, false) end)
      out[#out + 1] = "her hairpin hidden"
    end
  end) end)
  -- meshes of another skeleton: on her pose (bones by name), or at her head (x.head)
  for i, e in ipairs(look.extras or {}) do
    local x = st.extras[i]
    if x and not valid(x.comp) then x = nil end
    if x and x.head and not x.placed then place_on_head(x, mesh)
    elseif x then hair_watch(x) end
    if not x then
      local m = asset(e.path)
      -- (its bones posed by spring: a poseable mesh)
      local cls = try(function() return StaticFindObject(e.spring and "/Script/Engine.PoseableMeshComponent"
        or "/Script/Engine.SkeletalMeshComponent") end)
      local c = m and valid(cls) and try(function()
        return pawn:AddComponentByClass(cls, true, { Rotation = { X = 0, Y = 0, Z = 0, W = 1 },
          Translation = { X = 0, Y = 0, Z = 0 }, Scale3D = { X = 1, Y = 1, Z = 1 } }, false)
      end)
      if valid(c) then
        x = setmetatable({ comp = c, mesh = m, name = e.name or e.path:match("([^/.]+)$") }, { __index = e })
        st.extras[i] = x
        if e.sim then
          -- (its strands touch her body's capsules only: physics only, every channel but theirs ignored)
          try(function() c:SetCollisionObjectType(M.STRANDS.HAIR_CH) end)
          try(function() c:SetCollisionResponseToAllChannels(0) end)
          if e.collide then try(function() c:SetCollisionResponseToChannel(M.STRANDS.BODY_CH, 2) end) end
          try(function() c:SetCollisionEnabled(2) end)
        else
          try(function() c:SetCollisionEnabled(0) end)
        end
        try(function() c:SetSkeletalMesh(m, true) end)
        -- (only some of its sections: the rest hidden)
        if e.only then
          local hid = {}
          local keep = {}
          for _, k in ipairs(e.only) do keep[k] = true end
          for k in pairs(own_mats(m)) do if not keep[k] then hid[#hid + 1] = k end end
          table.sort(hid)
          if #hid > 0 and not sections(c, hid, false) then log(x.name .. ": its other sections NOT hidden") end
          x.hid = hid
        end
        -- (never welded to her: welded, its strands rode her head's body, and the gore mod re-making her bodies took
        -- her mesh off her capsule, left behind unseen, the game crashing on the way out to the menu, playtest)
        if e.head then
          try(function() c:SetVisibility(false, false) end)
          try(function() c:K2_AttachToComponent(mesh, FName("Bip001-Head"), 2, 2, 2, false) end)
          place_on_head(x, mesh)
        else
          try(function() c:K2_AttachToComponent(mesh, FName("None"), 2, 2, 2, false) end)
          try(function() c:SetMasterPoseComponent(mesh, true) end)
        end
        out[#out + 1] = "with " .. x.name
      end
    end
  end
  return #out > 0 and table.concat(out, ", ") or nil
end

-- her blade in its pin hidden (another's: it doesn't fold), shown again once drawn
local function unpin()
  for _, c in pairs(st.pinned) do if valid(c) then try(function() c:SetHiddenInGame(false, false) end) end end
  st.pinned = {}
end
local function hidden(c) return try(function() return c.bHiddenInGame end) == true end
-- the socket c rides on `on`: true on her head (its bone the head or under it), false elsewhere, nil not a socket
-- or bone of it (kept per socket; logged once each)
local function at_head(c, on)
  local sock = try(function() return c.AttachSocketName:ToString() end) or "None"
  local key = tostring(addr(on)) .. " " .. sock
  local k = st.sockets[key]
  if k ~= nil then if k == "none" then return nil end return k end
  local function real(n) return n and n ~= "None" and n ~= "" and n or nil end
  local name = sock ~= "None" and real(try(function() return on:GetSocketBoneName(FName(sock)):ToString() end))
  local v
  if name then v = false end
  for _ = 1, 64 do
    if not name then break end
    if name == M.HEAD then v = true; break end
    name = real(try(function() return on:GetParentBone(FName(name)):ToString() end))
  end
  if v == nil then st.sockets[key] = "none" else st.sockets[key] = v end
  log(string.format("blade on %s: %s", sock, v == nil and "no such socket (told by its distance from her head)"
    or v and "on her head (put away: hidden)" or "not on her head (shown)"))
  return v
end
local function pin(c, on, a)
  if on then
    st.pinned[a] = st.pinned[a] or c
    if not hidden(c) then try(function() c:SetHiddenInGame(true, false) end) end
  elseif st.pinned[a] then
    st.pinned[a] = nil
    try(function() c:SetHiddenInGame(false, false) end)
  end
end
-- a blade turned in its socket (weaponTurn) while it holds that blade: again once the game set it back
local function turn(t)
  if not valid(t.comp) or addr(try(function() return t.comp.SkeletalMesh end)) ~= addr(t.mesh) then return end
  local r = try(function() local q = t.comp.RelativeRotation; return { q.Pitch, q.Yaw, q.Roll } end)
  if r and math.abs(r[1] - t.rot.Pitch) < 0.5 and math.abs(r[2] - t.rot.Yaw) < 0.5 and math.abs(r[3] - t.rot.Roll) < 0.5 then return end
  try(function() t.comp:K2_SetRelativeRotation(t.rot, false, {}, true) end)
end
-- what of its own a strand component lost put back: its mesh (and its other sections hidden again), a leader pose
-- another set on it (its bones then follow that mesh's, no bodies of its own), its physics asset (no bodies: nothing
-- to simulate), its arms' and legs' bodies (back with bodies re-made). What was found, for the log
local function strands_mend(x)
  local c, out = x.comp, {}
  local function nm(o) return valid(o) and (try(function() return o:GetFName():ToString() end) or "?") or "none" end
  local cur = try(function() return c.SkeletalMesh end)
  if valid(x.mesh) and addr(cur) ~= addr(x.mesh) then
    out[#out + 1] = "its mesh was " .. nm(cur)
    try(function() c:SetSkeletalMesh(x.mesh, true) end)
    if x.hid and #x.hid > 0 then sections(c, x.hid, false) end
  end
  local lead = try(function() local l = c.MasterPoseComponent; if l and not valid(l) and l.Get then l = l:Get() end; return l end)
  if valid(lead) then
    out[#out + 1] = "it followed " .. nm(lead) .. "'s pose"
    try(function() c:SetMasterPoseComponent(nil, true) end)
  end
  -- (its override, else its mesh's: read as the engine does, should the call not be there)
  local got = try(function() return { c:GetPhysicsAsset() } end)
  local pa = got and got[1]
  if not got then
    pa = try(function() return c.PhysicsAssetOverride end)
    if not valid(pa) then pa = try(function() return c.SkeletalMesh.PhysicsAsset end) end
  end
  if valid(x.pa) and addr(pa) ~= addr(x.pa) then
    out[#out + 1] = "its physics asset was " .. nm(pa)
    try(function() c:SetPhysicsAsset(x.pa, true) end)
  end
  for _, b in ipairs(x.term or {}) do try(function() c:TermBodiesBelow(FName(b)) end) end
  return out
end
-- each frame: a strand stopped by something else mended and simulated again at once, before it shows hanging as
-- made. Logged: the first stop (what it had lost, how it looked), and STOPS_S s on how many frames it stopped in
M.STOPS_S = 5
local function strands_frame()
  for _, x in pairs(st.extras) do
    local c = x.comp
    if x.sim and x.placed and not x.off and valid(c) then
      x.frames = (x.frames or 0) + 1
      if try(function() return c:IsSimulatingPhysics(FName(x.on)) end) == false
        and try(function() return c:GetCollisionEnabled() end) == 2 then
        x.stops = (x.stops or 0) + 1
        local lost = strands_mend(x)
        if x.stops == 1 then
          local function ts(f) local v = try(f); return tostring(v) end
          local function nm(o) return valid(o) and (try(function() return o:GetFName():ToString() end) or "?") or "-" end
          x.stopAt, x.stopFrame = os.clock(), x.frames
          log(string.format("%s: its strands stopped (%.1f s after they were set going): %s; %s %s, its root %s %s, "
            .. "mesh %s, anim %s, visible %s, attached to %s at %s, its owner %s; mended and simulated again each frame "
            .. "from now", x.name, os.clock() - (x.simAt or 0), #lost > 0 and table.concat(lost, ", ") or "nothing of it lost",
            x.tips[1], ts(function() return c:IsSimulatingPhysics(FName(x.tips[1])) end), x.sim[1],
            ts(function() return c:IsSimulatingPhysics(FName(x.sim[1])) end), nm(try(function() return c.SkeletalMesh end)),
            nm(try(function() return c.AnimScriptInstance end)), ts(function() return c:IsVisible() end),
            nm(try(function() return c:GetAttachParent() end)), ts(function() return c.AttachSocketName:ToString() end),
            nm(try(function() return c:GetOwner() end))))
        elseif #lost > 0 and not x.saidLost then
          x.saidLost = true
          log(string.format("%s: stopped again, %s: mended", x.name, table.concat(lost, ", ")))
        end
        hair_sim(x, true)
      end
      if x.stopAt and not x.saidStops and os.clock() - x.stopAt >= M.STOPS_S then
        x.saidStops = true
        local f = x.frames - x.stopFrame + 1
        log(string.format("%s: its strands stopped on %d of the %d frames in the %g s after the first stop (%s)", x.name,
          x.stops, f, M.STOPS_S, x.stops >= f * 0.9 and "every frame: something holds them still each frame"
            or x.stops > 1 and "now and then" or "not again"))
      end
    end
  end
end

function M.frame(mesh)
  strands_frame()
  for _, x in pairs(st.extras) do if x.spring and x.placed and valid(x.comp) then spring_frame(x, mesh) end end
  for _, c in pairs(st.pins) do if valid(c) and not hidden(c) then try(function() c:SetHiddenInGame(true, false) end) end end
  for _, t in pairs(st.turns) do turn(t) end
  if #st.blades == 0 then return end
  local h0
  for _, c in ipairs(st.blades) do
    local a = addr(c)
    local on = a and try(function() return c:GetAttachParent() end)
    local head = valid(on) and at_head(c, on)
    if head ~= nil then pin(c, head, a)
    elseif a then
      local h = h0 or vec_of(function() return mesh:GetSocketLocation(FName(M.HEAD)) end)
      h0 = h
      if valid(on) and addr(on) ~= addr(mesh) and (try(function() return on:GetBoneIndex(FName(M.HEAD)) end) or -1) >= 0 then
        h = vec_of(function() return on:GetSocketLocation(FName(M.HEAD)) end) or h
      end
      local p = vec_of(function() return c:K2_GetComponentLocation() end)
      if p and h then
        local d = math.sqrt((p.X - h.X) ^ 2 + (p.Y - h.Y) ^ 2 + (p.Z - h.Z) ^ 2)
        if d < M.PIN_IN_CM then pin(c, true, a) elseif d > M.PIN_OUT_CM then pin(c, false, a)
        elseif st.pinned[a] then pin(c, true, a) end
      end
    end
  end
end

-- back as she was
local function restore(why)
  drop_extras()
  post_off()
  local w = st.was
  st.was = nil
  if not w then return end
  local pawn = st.pawn
  if not (valid(pawn) and addr(pawn) == w.pawn) then return end -- (a new Eve wears her own)
  st.was = w -- (unwear reads the materials kept)
  unpin()
  local mesh = try(function() return pawn.Mesh end)
  local had = valid(mesh) and try(function() return mesh.SkeletalMesh end)
  if valid(mesh) and valid(w.body) then unwear(mesh, w.body) end
  -- (what she wears now, for the log: back to Eve she still wore Raven's suit, playtest)
  local function nm(m) return valid(m) and tostring(try(function() return m:GetFName():ToString() end)) or "none" end
  local still = 0
  if valid(mesh) then
    local keep = valid(w.body) and addrs(own_mats(w.body)) or {}
    for i = 0, (try(function() return mesh:GetNumMaterials() end) or 0) - 1 do
      if ours(try(function() return mesh:GetMaterial(i) end), keep) then still = still + 1 end
    end
  end
  log(string.format("back to Eve: her body %s -> %s (kept %s), %d slot(s) still in a look's materials", nm(had),
    nm(valid(mesh) and try(function() return mesh.SkeletalMesh end)), nm(w.body), still))
  -- (her own sections all shown: hidden ones stay so on the component through a mesh change)
  if valid(mesh) then sections(mesh, nil) end
  if w.hair and valid(w.hair.comp) then
    local k = w.mats[addr(w.hair.comp)]
    if k and valid(k.mesh) then unwear(w.hair.comp, k.mesh) end
    if valid(w.hair.cls) then try(function() w.hair.comp:SetAnimInstanceClass(w.hair.cls) end) end
    if not w.hair.vis then try(function() w.hair.comp:SetVisibility(false, false) end) end
  end
  if valid(w.face) and valid(w.faceMesh) then unwear(w.face, w.faceMesh) end
  for _, c in ipairs(w.hidden) do if valid(c) then try(function() c:SetVisibility(true, false) end) end end
  for _, x in ipairs(w.pins or {}) do if valid(x.comp) then try(function() x.comp:SetHiddenInGame(x.hid, false) end) end end
  st.pins, st.turns = {}, {}
  -- (her sword back where ours still is: one the game swapped meanwhile stays the game's)
  for _, x in ipairs(w.weapons) do
    if valid(x.comp) and valid(x.mesh) and addr(try(function() return x.comp.SkeletalMesh end)) == addr(x.ours) then
      unwear(x.comp, x.mesh)
    end
    if valid(x.comp) and x.rot then try(function() x.comp:K2_SetRelativeRotation(x.rot, false, {}, true) end) end
  end
  st.was = nil
  log("back to Eve (" .. why .. ")")
end

-- every tick of hers (main.lua): at most once a second, and never while she is dead or a ragdoll (her body is the
-- game's death's then, or another mod's: the gore mod's cut pieces are her body's own bones)
function M.tick(pawn, mesh, dead)
  local now = os.clock()
  if now < st.next then return end
  st.next = now + 1
  if addr(pawn) ~= addr(st.pawn) then
    -- a new Eve: what was hidden went with the old one
    st.pawn, st.was, st.extras, st.blades, st.pinned, st.listed, st.pins, st.sockets, st.cut = pawn, nil, {}, {}, {}, nil, {}, {}, nil
    st.turns, st.settle, st.settleTicks = {}, {}, nil
  end
  settle()
  -- (a pick made while she is dead waits till she is up again)
  if dead then return end
  local who = cfg().who or "eve"
  local look = M.LOOKS[who]
  local blade = cfg().blade ~= false
  if who ~= st.who or blade ~= st.blade then
    if st.who ~= "eve" then restore(who ~= st.who and ("now " .. who) or (blade and "her blade on" or "her blade off")) end
    -- (a look going on: its meshes are wanted now, settle's watch over Eve's is over)
    if look then st.settle, st.settleTicks = {}, nil end
    st.who, st.blade = who, blade
    if look then log("now " .. look.label .. (look.weapon and not blade and ", Eve's sword kept" or "")) end
  end
  if not look then st.blades = {}; return end
  -- her weapon slots, watched each frame for the pin (M.frame)
  local b = {}
  for _, s in ipairs(slots(pawn)) do if M.WEAPON[s.slot] then b[#b + 1] = s.comp end end
  st.blades = b
  -- (a part of her off: nothing swapped till it is back)
  local off
  for _, n in ipairs(M.MAIN) do
    if try(function() return mesh:IsSimulatingPhysics(FName(n)) end) == true then off = n; break end
  end
  if off then
    if not st.cut then log("a part of her is off (" .. off .. " simulated): nothing of hers swapped till it is back") end
    st.cut = off
    for _, x in pairs(st.extras) do if valid(x.comp) then hair_watch(x) end end
    return
  end
  if st.cut then st.cut = nil; log("whole again: " .. look.label .. "'s look kept on") end
  local line = apply(pawn, mesh, look)
  if line then log(look.label .. ": " .. line) end
  if not st.listed then
    -- (once per Eve: what is in her slots, for the next look at what shows)
    st.listed = true
    local l = {}
    for _, s in ipairs(slots(pawn)) do
      local m = try(function() return s.comp.SkeletalMesh end)
      l[#l + 1] = tostring(s.slot) .. " " .. tostring(valid(m) and try(function() return m:GetFName():ToString() end) or "-")
    end
    log("her slots: " .. table.concat(l, ", "))
  end
end
-- the pick changed: at once
function M.apply_now() st.next = 0 end
-- can she play as who: false once her body isn't in the game (Scarlet without the NIKKE content), nil while that
-- can't be told (nothing may load now)
function M.available(who)
  local look = M.LOOKS[who]
  if not look then return true end
  if st.failed[look.body] then return false end
  if st.found[look.body] or valid(try(function() return StaticFindObject(look.body) end)) then return true end
  if ctx.may_load and not ctx.may_load() then return nil end
  if asset(look.body) then st.found[look.body] = true; return true end
  st.failed[look.body] = true
  log(string.format("%s: %s not found%s", look.label, look.body, look.dlc and " (needs its DLC)" or ""))
  return false
end
-- who she looks like now (eve when nothing is on her)
function M.current() return st.who end
-- the level reloaded: nothing of the old Eve touched
function M.forget()
  st.pawn, st.was, st.extras, st.blades, st.pinned, st.listed, st.pins, st.sockets, st.cut = nil, nil, {}, {}, {}, nil, {}, {}, nil
  st.turns, st.settle, st.settleTicks = {}, {}, nil
end

M._state = function() return st end
return M
