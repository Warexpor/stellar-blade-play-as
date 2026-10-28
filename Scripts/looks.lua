-- looks.lua: Eve wears another character (settings.who). Her own components take the other's meshes, so her
-- animations, physics and everything another mod does with her body (the gore mod's cuts, struggle, death face) stay
-- hers:
--   tachy: her NPC body (hair in it) and face (CH_NPC_TachyNPC_Body, _Face_Jali2: built on Eve's skeleton, the beach
--     scenes' Tachy), Eve's hair hidden
--   scarlet: the DLC boss's body (CH_M_NA_961, on Eve's skeleton, head and hair in it), Eve's face and hair hidden.
--     Without the DLC it isn't found and nothing changes
--   raven: the game has no Raven head on Eve's skeleton (hers is on a skeleton of its own): Raven's suit as Eve's
--     outfit (CH_P_EVE_11) and Raven's own hair (CH_M_NA_53_Hair) on a component of its own, posed by Eve's body
--     (master pose, bones by name), Eve's hair hidden
-- Each takes her own blade too (the game's EquipmentTable: Tachy_Sword, Raven_Blade, Scarlet_Sword) in place of
-- Eve's drawn sword (CH_W_Sword_01 in a weapon slot; the folded one the game shows when it is away is left, so it
-- still goes away as hers): on a skeleton of its own, it doesn't fold, and her sword's gore (its fall, a blade cut
-- through it) takes it as it took hers.
-- Each mesh goes on with its own materials (Eve's outfit's, set on her components, made the others' parts wrong or
-- glowing), Eve's outfit accessories are hidden, and another's blade folded into her hairpin (it doesn't fold) too.
-- What the game puts back (a level, a respawn, the outfit menu, a scene) is set again within a second; "eve" gives
-- back what she wore. While it is on, an outfit change in the game's menu is overridden. settings.blade false: her
-- own sword stays.
local M = {}
local ctx, try, valid
local function cfg() return ctx.settings or {} end
local function log(s) ctx.log("look: " .. s) end

local P = "/Game/Art/Character/"
M.LOOKS = {
  tachy = { label = "Tachy", body = P .. "NPC/CH_NPC_TachyNPC/CH_NPC_TachyNPC_Body.CH_NPC_TachyNPC_Body",
    face = P .. "NPC/CH_NPC_TachyNPC/CH_NPC_TachyNPC_Face_Jali2.CH_NPC_TachyNPC_Face_Jali2", hide = { hair = true },
    weapon = P .. "Weapon/Sword/CH_W_Sword_02/CH_W_Sword_02.CH_W_Sword_02" },
  scarlet = { label = "Scarlet", body = "/Game/DLC_2/Art/Character/Monster/CH_M_NA_961/CH_M_NA_961.CH_M_NA_961",
    hide = { face = true, hair = true }, dlc = true,
    weapon = "/Game/DLC_2/Art/Character/Monster/CH_M_NA_961/CH_M_NA_961_Weapon_01.CH_M_NA_961_Weapon_01" },
  raven = { label = "Raven", body = P .. "PC/CH_P_EVE_11/CH_P_EVE_11.CH_P_EVE_11",
    extra = P .. "Monster/CH_M_NA_53/CH_M_NA_53_Hair.CH_M_NA_53_Hair", hide = { hair = true },
    weapon = P .. "Monster/CH_M_NA_53/CH_M_NA_53_Weapon.CH_M_NA_53_Weapon" },
}
-- her mesh slots (MeshInfoList's MeshSlot, ESBSkelMeshSlot): the face, the hair ones (Hair1, Ponytail, PonytailShort)
-- and her outfit's accessories (Accessory1-5: Eve's, hidden on the others)
M.FACE, M.HAIR, M.ACC = 1, { [2] = true, [3] = true, [4] = true }, { [9] = true, [10] = true, [11] = true, [12] = true, [13] = true }
-- her weapon slots (Weapon1-4), and her drawn sword's mesh in them
M.WEAPON, M.SWORD = { [5] = true, [6] = true, [7] = true, [8] = true }, "CH_W_Sword_01"

-- her sword folded into her hairpin: the same component at her head (the gore mod's playtests). Another's blade
-- doesn't fold, so there it is hidden: under PIN_IN_CM from the head of what it hangs on, shown again past PIN_OUT_CM
-- (drawn). (What it hangs on, not her body: the gore mod's photo mode moves a cut-off head and what rides it, the
-- pinned blade too, onto a copy of her mesh lying where the head fell, and measured from her body's head the blade
-- showed there, playtest)
M.PIN_IN_CM, M.PIN_OUT_CM = 40, 60

local st = { pawn = nil, who = "eve", blade = true, was = nil, next = 0, failed = {}, blades = {}, pinned = {} }

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
-- her slots; face: her face's (ESBMesh_Face, or another slot holding a mesh named like a face: in game it is in
-- Etc1, 14)
local function slots(pawn)
  local out = {}
  try(function() pawn.MeshInfoList:ForEach(function(_, e)
    local info = e:get()
    local c = info.MeshComponent
    if valid(c) then
      local n = mesh_name(c)
      out[#out + 1] = { slot = info.MeshSlot, comp = c,
        face = info.MeshSlot == M.FACE or (n ~= nil and n:find("Face", 1, true) ~= nil and not M.WEAPON[info.MeshSlot]) }
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

-- a mesh on one of her components with that mesh's own materials: what the game set on the component for Eve's
-- (her outfit's material instances) stayed on by slot number, on the other's parts it showed wrong or glowing.
-- What was on it first is kept for restore
local function wear(c, m)
  local a = addr(c)
  if a and not st.was.mats[a] then
    local n = try(function() return c:GetNumMaterials() end) or 0
    local was = {}
    for i = 0, n - 1 do was[i] = try(function() return c:GetMaterial(i) end) end
    st.was.mats[a] = { comp = c, mats = was, n = n }
  end
  try(function() c:SetSkeletalMesh(m, true) end)
  local i = 0
  try(function() m.Materials:ForEach(function(_, e)
    local mi = try(function() return e:get().MaterialInterface end)
    local k = i
    if valid(mi) then try(function() c:SetMaterial(k, mi) end) end
    i = i + 1
  end) end)
end
-- the component's first mesh back, with the materials it had
-- the game put a mesh of its own on c over ours (m, ours, was on it): it and the materials the game gave it are what
-- she wears now, kept for restore. A slot still holding m's own material (the game left ours on it) keeps the one kept
local function regear(c, cur, m)
  local w = st.was.mats[addr(c)]
  local n = try(function() return c:GetNumMaterials() end) or 0
  local own = {}
  local i = 0
  try(function() m.Materials:ForEach(function(_, e) own[i] = addr(try(function() return e:get().MaterialInterface end)); i = i + 1 end) end)
  local mats = {}
  for k = 0, n - 1 do
    local mt = try(function() return c:GetMaterial(k) end)
    if w and mt and own[k] and addr(mt) == own[k] then mt = w.mats[k] end
    mats[k] = mt
  end
  st.was.mats[addr(c)] = { comp = c, mats = mats, n = n }
  return cur
end
local function unwear(c, m)
  try(function() c:SetSkeletalMesh(m, true) end)
  local w = st.was and st.was.mats[addr(c)]
  if not w then return end
  for i = 0, w.n - 1 do
    local mt = w.mats[i]
    if valid(mt) then try(function() c:SetMaterial(i, mt) end) end
  end
end

local function hide(c, body)
  if not valid(c) or addr(c) == addr(body) then return end
  if try(function() return c:IsVisible() end) ~= true then return end
  try(function() c:SetVisibility(false, false) end)
  st.was.hidden[#st.was.hidden + 1] = c
end

local function drop_extra()
  local x = st.extra
  st.extra = nil
  if valid(x) then try(function() x:K2_DestroyComponent(x) end) end
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
    if not fresh and valid(cur) then st.was.body = regear(mesh, cur, body) end
    wear(mesh, body)
    out[#out + 1] = "body " .. look.body:match("([^/.]+)$")
  end
  for _, s in ipairs(slots(pawn)) do
    if s.face then
      if look.hide.face then hide(s.comp, mesh)
      elseif look.face then
        local f = asset(look.face)
        local fc = try(function() return s.comp.SkeletalMesh end)
        if f and addr(fc) ~= addr(f) then
          if not fresh and valid(fc) and addr(s.comp) == addr(st.was.face) then st.was.faceMesh = regear(s.comp, fc, f) end
          wear(s.comp, f)
          out[#out + 1] = "face " .. look.face:match("([^/.]+)$")
        end
      end
    elseif M.HAIR[s.slot] and look.hide.hair or M.ACC[s.slot] then
      hide(s.comp, mesh)
    elseif M.WEAPON[s.slot] and look.weapon and cfg().blade ~= false then
      local cur = try(function() return s.comp.SkeletalMesh end)
      local nm = valid(cur) and try(function() return cur:GetFName():ToString() end)
      local w = nm == M.SWORD and asset(look.weapon)
      if w then
        st.was.weapons[#st.was.weapons + 1] = { comp = s.comp, mesh = cur, ours = w }
        wear(s.comp, w)
        out[#out + 1] = "blade " .. look.weapon:match("([^/.]+)$")
      end
    end
  end
  -- a mesh of another skeleton on her pose (bones by name)
  if look.extra and not valid(st.extra) then
    local x = asset(look.extra)
    local cls = try(function() return StaticFindObject("/Script/Engine.SkeletalMeshComponent") end)
    local c = x and valid(cls) and try(function()
      return pawn:AddComponentByClass(cls, true, { Rotation = { X = 0, Y = 0, Z = 0, W = 1 },
        Translation = { X = 0, Y = 0, Z = 0 }, Scale3D = { X = 1, Y = 1, Z = 1 } }, false)
    end)
    if valid(c) then
      try(function() c:SetCollisionEnabled(0) end)
      try(function() c:SetSkeletalMesh(x, true) end)
      try(function() c:K2_AttachToComponent(mesh, FName("None"), 2, 2, 2, true) end)
      try(function() c:SetMasterPoseComponent(mesh, true) end)
      st.extra = c
      out[#out + 1] = "with " .. look.extra:match("([^/.]+)$")
    end
  end
  return #out > 0 and table.concat(out, ", ") or nil
end

-- her blade in its pin hidden (another's: it doesn't fold), shown again once drawn
local function unpin()
  for _, c in pairs(st.pinned) do if valid(c) then try(function() c:SetHiddenInGame(false, false) end) end end
  st.pinned = {}
end
local function vec_of(f) return try(function() local v = f(); return { X = v.X, Y = v.Y, Z = v.Z } end) end
function M.frame(mesh)
  if #st.blades == 0 then return end
  local h0 = vec_of(function() return mesh:GetSocketLocation(FName("Bip001-Head")) end)
  for _, c in ipairs(st.blades) do
    local a = addr(c)
    local p = a and vec_of(function() return c:K2_GetComponentLocation() end)
    local on = a and try(function() return c:GetAttachParent() end)
    local h = h0
    if valid(on) and addr(on) ~= addr(mesh) and (try(function() return on:GetBoneIndex(FName("Bip001-Head")) end) or -1) >= 0 then
      h = vec_of(function() return on:GetSocketLocation(FName("Bip001-Head")) end) or h0
    end
    if p and h then
      local d = math.sqrt((p.X - h.X) ^ 2 + (p.Y - h.Y) ^ 2 + (p.Z - h.Z) ^ 2)
      if not st.pinned[a] and d < M.PIN_IN_CM then
        try(function() c:SetHiddenInGame(true, false) end)
        st.pinned[a] = c
      elseif st.pinned[a] and d > M.PIN_OUT_CM then
        try(function() c:SetHiddenInGame(false, false) end)
        st.pinned[a] = nil
      end
    end
  end
end

-- back as she was
local function restore(why)
  drop_extra()
  local w = st.was
  st.was = nil
  if not w then return end
  local pawn = st.pawn
  if not (valid(pawn) and addr(pawn) == w.pawn) then return end -- (a new Eve wears her own)
  st.was = w -- (unwear reads the materials kept)
  unpin()
  local mesh = try(function() return pawn.Mesh end)
  if valid(mesh) and valid(w.body) then unwear(mesh, w.body) end
  if valid(w.face) and valid(w.faceMesh) then unwear(w.face, w.faceMesh) end
  for _, c in ipairs(w.hidden) do if valid(c) then try(function() c:SetVisibility(true, false) end) end end
  -- (her sword back where ours still is: one the game swapped meanwhile stays the game's)
  for _, x in ipairs(w.weapons) do
    if valid(x.comp) and valid(x.mesh) and addr(try(function() return x.comp.SkeletalMesh end)) == addr(x.ours) then
      unwear(x.comp, x.mesh)
    end
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
    st.pawn, st.was, st.extra, st.blades, st.pinned, st.listed = pawn, nil, nil, {}, {}, nil
  end
  -- (a pick made while she is dead waits till she is up again)
  if dead then return end
  local who = cfg().who or "eve"
  local look = M.LOOKS[who]
  local blade = cfg().blade ~= false
  if who ~= st.who or blade ~= st.blade then
    if st.who ~= "eve" then restore(who ~= st.who and ("now " .. who) or (blade and "her blade on" or "her blade off")) end
    st.who, st.blade = who, blade
    if look then log("now " .. look.label .. (look.weapon and not blade and ", Eve's sword kept" or "")) end
  end
  if not look then st.blades = {}; return end
  local line = apply(pawn, mesh, look)
  if line then log(look.label .. ": " .. line) end
  -- her weapon slots, watched each frame for the pin (M.frame)
  local b = {}
  for _, s in ipairs(slots(pawn)) do if M.WEAPON[s.slot] then b[#b + 1] = s.comp end end
  st.blades = b
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
-- who she looks like now (eve when nothing is on her)
function M.current() return st.who end
-- the level reloaded: nothing of the old Eve touched
function M.forget() st.pawn, st.was, st.extra, st.blades, st.pinned, st.listed = nil, nil, nil, {}, {}, nil end

M._state = function() return st end
return M
