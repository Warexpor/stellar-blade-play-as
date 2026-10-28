-- voice.lua: her voice as the one she plays (settings.voice). The game voices Eve through SoundCues (Sound/Voice/PC,
-- eve_vo_attack_L1_Cue and so on: a random pick of SoundWaves under Sound/Dialogue/ActionVoice/Eve), fired by her
-- animations. Each of those cues keeps its graph; only the SoundWave on each of its wave players is swapped for one of
-- the other's, of the same kind (a light attack's for a light attack's, a heavy hit's for a heavy hit's), so the
-- cue's volume, attenuation and sound class (the game's voice volume slider) stay Eve's. What was on it is put back
-- by its path, not kept by pointer: unreferenced meanwhile, the garbage collector may have freed Eve's wave, and
-- loading it again by name is safe where the old pointer would not be.
-- Their recordings are quieter than Eve's (playtest): her cues' VolumeMultiplier is raised by settings.voiceVolume
-- (VOLUME) while another's voice is on them, and given back by path with her voice.
-- Social and fishing lines and the scenes' voice stay Eve's (the others have nothing like them).
local M = {}
local ctx, try, valid

-- Eve's cues by kind (the game's own: the attack lines, casts, hits, death, breath), under Sound/Voice/PC
M.EVE = {
  atk_s = { "eve_vo_attack_s1_Cue", "eve_vo_attack_s1a_Cue", "eve_vo_attack_s3_Cue", "eve_vo_attack_s3p_Cue",
    "eve_vo_social_Motion_Strong_Cue", "eve_vo_social_Motion_Strong_Random_Cue",
    "SkillActionVo/eve_Skill_vo_attack_s1a_Cue", "SkillActionVo/eve_Skill_vo_attack_M1P_Cue" },
  atk_m = { "eve_vo_attack_M1_Cue", "eve_vo_attack_M2_Cue", "SkillActionVo/eve_Skill_vo_attack_M1_Cue",
    "SkillActionVo/eve_Skill_vo_attack_M2_Cue" },
  atk_l = { "eve_vo_attack_L1_Cue", "eve_vo_attack_L2_Cue", "SkillActionVo/eve_Skill_vo_attack_L1_Cue",
    "SkillActionVo/eve_Skill_vo_attack_L2_Cue", "SkillActionVo/eve_Skill_vo_attack_L2_High_Cue" },
  cast_s = { "eve_vo_Cast_S_Cue", "SkillActionVo/eve_Skill_vo_Cast_S_Cue", "SkillActionVo/eve_Skill_vo_attack_Cast_S_Cue",
    "SkillActionVo/eve_Skill_vo_attack_Cast_SP_Cue" },
  cast_m = { "eve_vo_Cast_M_Cue", "eve_vo_Cast_M_high_Cue", "SkillActionVo/eve_Skill_vo_Cast_M_Cue" },
  cast_l = { "eve_vo_Cast_L_Cue", "eve_vo_Cast_L2_Cue", "SkillActionVo/eve_Skill_vo_Cast_L_Cue",
    "SkillActionVo/eve_Skill_vo_Cast_L2_Cue" },
  dmg_s = { "eve_vo_dmg_Cue", "eve_vo_dmg_Random_Cue", "eve_vo_dmg_Motion_Cue", "SkillActionVo/eve_Skill_vo_dmg_Cue" },
  dmg_m = { "eve_vo_dmg2_Cue", "SkillActionVo/eve_Skill_vo_dmg2_Cue" },
  dmg_l = { "eve_vo_dmg_strong_Cue", "eve_vo_dmg_strong_Land_Stiff_Cue", "SkillActionVo/eve_Skill_vo_dmg_Strong_Cue" },
  die = { "eve_vo_die_Cue", "eve_vo_die_reverb_cue", "eve_vo_dmg_long_Cue", "SkillActionVo/eve_Skill_vo_dmg_long_Cue" },
  breath = { "eve_vo_breath_s_Cue", "eve_vo_breath_s_Random_Cue" },
}
M.EVE_DIR = "/Game/Sound/Voice/PC/"
M.VOLUME = 1.5

-- the others' recordings by the same kinds, under Sound/Dialogue/ActionVoice/<dir> (as their own cues pick them:
-- Tachy's mirror Eve's one for one, Raven's and Scarlet's go by size, S to XL; Raven has no death line, her
-- heaviest hits stand in)
local function n(fmt, ...)
  local out = {}
  for _, i in ipairs({ ... }) do out[#out + 1] = string.format(fmt, i) end
  return out
end
M.VOICES = {
  tachy = { dir = "Tachy",
    atk_s = n("vo_Tachy_Atk_s%d", 1, 2, 3, 4, 5), atk_m = n("vo_Tachy_Atk_m%d", 1, 2, 3, 4),
    atk_l = n("vo_Tachy_Atk_l%d", 5, 6, 7, 8), cast_s = n("vo_Tachy_Atk_l%d", 1, 2, 3, 4),
    cast_m = n("vo_Tachy_Atk_l%d", 1, 2, 3, 4), cast_l = n("vo_Tachy_Atk_xl%d", 1, 2, 3),
    dmg_s = n("vo_Tachy_dmg_s%d", 1, 2, 3, 4, 5), dmg_m = n("vo_Tachy_dmg_s%d", 1, 2, 3, 4, 5),
    dmg_l = n("vo_Tachy_dmg_m%d", 1, 2, 3), die = n("vo_Tachy_dmg_xl%d", 1, 2, 3),
    breath = n("vo_Tachy_breath_s%d", 1, 2) },
  raven = { dir = "Raven",
    atk_s = n("vo_Raven_atk_s%d", 1, 2, 4), atk_m = n("vo_Raven_atk_s%d", 1, 2, 3, 4),
    atk_l = n("vo_Raven_atk_l%d", 1, 2, 3, 4), cast_s = n("vo_Raven_cast_s%d", 1, 2),
    cast_m = n("vo_Raven_cast_m%d", 1, 2, 3), cast_l = n("vo_Raven_cast_l%d", 1, 2),
    dmg_s = n("vo_Raven_dmg_s%d", 1, 2, 3, 4, 5), dmg_m = n("vo_Raven_dmg_m%d", 1, 2, 3),
    dmg_l = n("vo_Raven_dmg_l%d", 1, 2, 3, 4), die = n("vo_Raven_dmg_xl%d", 1, 2, 3, 4),
    breath = n("vo_Raven_breath_s%d", 1, 2, 3, 4) },
  scarlet = { dir = "Scarlet",
    atk_s = n("vo_Scarlet_Atk_S_%d", 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11), atk_m = n("vo_Scarlet_Atk_M_%d", 1, 2, 3, 4, 5, 6),
    atk_l = n("vo_Scarlet_Atk_L_%d", 1, 2, 3, 4, 5, 6, 7), cast_s = n("vo_Scarlet_Cast_S_%d", 1, 2, 3, 4, 5),
    cast_m = n("vo_Scarlet_Cast_M_%d", 1, 2, 3, 4, 5), cast_l = n("vo_Scarlet_Cast_L_%d", 1, 2, 3, 4, 5),
    dmg_s = n("vo_Scarlet_Dmg_S_%d", 1, 2, 3, 4, 5), dmg_m = n("vo_Scarlet_Dmg_M_%d", 1, 2, 3, 4, 5),
    dmg_l = n("vo_Scarlet_Dmg_L_%d", 1, 2, 3, 4, 5), die = n("vo_Scarlet_Dead_%d", 1, 2, 3, 4, 5),
    breath = n("vo_Scarlet_groggy_S_%d", 1, 2, 3, 4, 5) },
}

-- st.swapped: wave player address -> { node, path (Eve's wave), ours (its address) }; st.who: whose voice is on
-- st.vol: Eve's cue path -> its own VolumeMultiplier
local st = { who = "eve", swapped = {}, next = 0, missing = {}, owed = false, vol = {} }

function M.init(c)
  ctx, try, valid = c, c.try, c.valid
end
local function log(s) ctx.log("voice: " .. s) end
local function addr(o) return valid(o) and try(function() return o:GetAddress() end) or nil end
local function obj_path(name)
  local p = name:sub(1, 1) == "/" and name or (M.EVE_DIR .. name)
  return p .. "." .. p:match("([^/]+)$")
end
local function wave_path(dir, name)
  local p = "/Game/Sound/Dialogue/ActionVoice/" .. dir .. "/" .. name .. "_VO"
  return p .. "." .. p:match("([^/]+)$")
end
-- (loaded from the pak only when main.lua's may_load says so: a load while the game loads a level waited on it, the
-- gore mod found, an endless loading screen)
local function may_load() return not ctx.may_load or ctx.may_load() end
local function find(path, load)
  local o = try(function() return StaticFindObject(path) end)
  if not valid(o) and load and LoadAsset and may_load() then o = try(function() return LoadAsset(path) end) end
  return valid(o) and o or nil
end
-- an object's path from its full name ("SoundWave /Game/...vo_eve_atk_l1_VO.vo_eve_atk_l1_VO")
local function path_of(o)
  local full = valid(o) and try(function() return o:GetFullName() end)
  return full and (full:match("^%S+%s+(.+)$") or full) or nil
end

-- every wave player under a cue's graph
local function players(cue)
  local out, seen = {}, {}
  local function walk(node, depth)
    local a = addr(node)
    if not a or seen[a] or depth > 12 then return end
    seen[a] = true
    local cls = try(function() return node:GetClass():GetFName():ToString() end) or ""
    if cls == "SoundNodeWavePlayer" then out[#out + 1] = node; return end
    try(function() node.ChildNodes:ForEach(function(_, e) walk(e:get(), depth + 1) end) end)
  end
  walk(try(function() return cue.FirstNode end), 0)
  return out
end

-- Eve's waves back on every player we changed (by their paths: loaded again if they went; one that can't be loaded
-- now is owed, tried again on the next tick)
local function restore(why)
  local n, lost, left = 0, 0, {}
  for a, s in pairs(st.swapped) do
    if valid(s.node) and addr(s.node) == a then
      local w = find(s.path, true)
      if w and try(function() s.node.SoundWave = w; return true end) then n = n + 1
      elseif not may_load() then left[a] = s
      else lost = lost + 1 end
    end
  end
  st.swapped, st.owed = left, next(left) ~= nil
  -- (her cues' own volume; one not loaded now comes back from the pak with its own)
  for p, v in pairs(st.vol) do
    local cue = find(p, false)
    if cue then try(function() cue.VolumeMultiplier = v end) end
  end
  st.vol = {}
  if n + lost > 0 then log(string.format("Eve's voice back on %d recording slot(s)%s (%s)%s", n,
    lost > 0 and string.format(", %d not found", lost) or "", why, st.owed and ", the rest once the level is in" or "")) end
end

-- the other's waves on Eve's cues (again where the game loaded a cue anew): how many players changed now
-- (only the recordings put on a slot are loaded, and kept by it; one the game lacks is never asked for again: a load
-- that fails is a synchronous wait on the game thread each time)
local function apply(v)
  local changed, cues = 0, 0
  for kind, list in pairs(M.EVE) do
    local theirs = {}
    for _, nm in ipairs(v[kind] or {}) do
      local p = wave_path(v.dir, nm)
      if not st.missing[p] then theirs[#theirs + 1] = p end
    end
    for _, name in ipairs(#theirs > 0 and list or {}) do
      local cp = obj_path(name)
      local cue = find(cp, false)
      if cue then
        cues = cues + 1
        -- (louder: theirs are quieter than hers)
        local cur = try(function() return cue.VolumeMultiplier end)
        if cur then
          if not st.vol[cp] then st.vol[cp] = cur end
          local want = st.vol[cp] * (tonumber((ctx.settings or {}).voiceVolume) or M.VOLUME)
          if math.abs(cur - want) > 1e-4 then try(function() cue.VolumeMultiplier = want end) end
        end
        for i, node in ipairs(players(cue)) do
          local a = addr(node)
          local cur = try(function() return node.SoundWave end)
          -- (one the game lacks: the next of hers instead)
          local p, want
          while a and #theirs > 0 do
            p = theirs[(i - 1) % #theirs + 1]
            if path_of(cur) == p then break end
            want = find(p, true)
            -- (not loaded now isn't missing: next time)
            if want or not may_load() then break end
            st.missing[p] = true
            log(p .. " not found")
            for j = #theirs, 1, -1 do if theirs[j] == p then table.remove(theirs, j) end end
          end
          if want then
            -- (Eve's wave, the first time: what goes back)
            if not st.swapped[a] then
              local was = path_of(cur)
              if was then st.swapped[a] = { node = node, path = was } end
            end
            if st.swapped[a] and try(function() node.SoundWave = want; return true end) then changed = changed + 1 end
          end
        end
      end
    end
  end
  return changed, cues
end

-- the voice wanted (nil: Eve's), at most every `every` s: Eve's cues the game loads later get it on the next look
function M.tick(who, every)
  local now = os.clock()
  if who ~= st.who then
    if st.who ~= "eve" then restore("now " .. (who or "eve")) end
    st.who, st.next = who or "eve", 0
  elseif st.owed and may_load() then restore("owed")
  end
  local v = M.VOICES[st.who]
  if not v or now < st.next then return end
  st.next = now + (every or 3)
  local changed, cues = apply(v)
  if changed > 0 then log(string.format("%s's voice on %d recording slot(s) of %d of Eve's cues", st.who, changed, cues)) end
end
function M.off(why) if st.who ~= "eve" then restore(why) end; st.who = "eve" end

M._state = function() return st end
return M
