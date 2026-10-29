-- menu.lua: the in-game picker (F4, or settings.menuPad on the controller), made as the Stellar Blade Gore mod's F3
-- menu is (its grid, palette, fonts, focus boxes, help line and key hints: the game's own settings screen), plain UMG
-- widgets made here at runtime, nothing in the pak. One tab, its rows the characters, her voice and blade, Apply and
-- Close; right of the rows the game's own art of the one under the focus (its album pictures; Eve's from the NIKKE
-- update). Up/Down (or the D-pad) goes through them; Enter / A on a name picks her ("Picked") and goes to Apply, where
-- Enter / A puts her on; < > (or the D-pad) turns her voice or blade on or off. Nothing changes on her before Apply; Backspace /
-- B or F4 closes, a pick not applied dropped. The mouse: hover moves the focus, a click picks a name, turns a box, or
-- applies. The world goes on while it is open; her moving and looking are held.
-- Its text is set by StellarBladePlayAs's own DLL (StellarBladePlayAsText: UE4SS can't make an FText in this game), else by UE4SS's
-- FText where UE4SS found the engine's constructor, else there is no menu (settings.lua's who still picks).
local M = {}
local ctx, log, try, valid

local DIR = "ue4ss/Mods/StellarBladePlayAs/"
local HOOK, OK, ANS = DIR .. "playas.hook", DIR .. "playas.ok", DIR .. "playas.ans"
M.HOOK_FN = "/Script/SB.SBCheatManager:SBSnapShot"
M.CDO = "/Script/SB.Default__SBCheatManager"
-- the game's settings screen's fonts (only as found in memory, never loaded)
M.FONT = "/Game/Art/Font/Rajdhani-BoldM_Font.Rajdhani-BoldM_Font"
M.FONT_MID = "/Game/Art/Font/Mideum.Mideum"
M.FONT_BOLD = "/Game/Art/Font/Bold.Bold"
M.ICONS = "/Game/Art/UI/Texture/Interaction/"
-- each one's picture: the album's (2048 square, her whole body in the middle, fading out at the bottom), Eve's the
-- NIKKE update's result screen's (800 x 2570, head to toe)
M.CHARS = {
  { key = "eve", name = "Eve", tex = "/Game/DLC_2/Art/UI/Texture/eve_result.eve_result", aspect = 800 / 2570,
    about = "Herself: her own body, face, hair, sword and voice." },
  { key = "tachy", name = "Tachy", tex = "/Game/Art/UI/Texture/Album/NPC/image/CH_NPC_TachyNPC.CH_NPC_TachyNPC", aspect = 1,
    about = "Tachy's body, face and hair, her sword and her voice. Eve's moves and skills." },
  { key = "raven", name = "Raven", tex = "/Game/Art/UI/Texture/Album/NPC/image/CH_NPC_Raven.CH_NPC_Raven", aspect = 1,
    about = "Raven's suit, face and long hair, her blade and her voice. Her face doesn't move with Eve's expressions." },
  { key = "scarlet", name = "Scarlet", tex = "/Game/DLC_2/Art/UI/Texture/Album/NPC/image/CH_NPC_Scarlet.CH_NPC_Scarlet", aspect = 1,
    about = "Scarlet's body, head and hair, her sword and her voice. Needs the NIKKE collaboration content." },
}
-- (as the F3 menu's, less its tabs and reset; the keyboard's Exit is the menu's key, M.hints_kb)
M.HINTS = {
  kb = { { { "PC/KeyIcon_KeyBoard_Comma", "PC/KeyIcon_KeyBoard_Period" }, "Adjust", { "<", ">" } },
    { { "PC/KeyIcon_KeyBoard_Enter" }, "Select", "ENTER" } },
  xbox = { { { "XBOX/KeyIcon_XboxOne_Gamepad_DPad_X" }, "Adjust", "D-PAD" },
    { { "XBOX/KeyIcon_XboxOne_Gamepad_FaceButton_Bottom" }, "Select", "A" },
    { { "XBOX/KeyIcon_XboxOne_Gamepad_FaceButton_Right" }, "Exit", "B" } },
  playstation = { { { "DualSense/KeyIcon_DualSense_Gamepad_DPad_X" }, "Adjust", "D-PAD" },
    { { "DualSense/KeyIcon_DualSense_Gamepad_FaceButton_Bottom" }, "Select", "X" },
    { { "DualSense/KeyIcon_DualSense_Gamepad_FaceButton_Right" }, "Exit", "O" } },
}
M.KEYS = {
  -- (the arrow keys come from main.lua's binds, M.nav: the engine never sees them down)
  up = { "Gamepad_DPad_Up", "Gamepad_LeftStick_Up" },
  down = { "Gamepad_DPad_Down", "Gamepad_LeftStick_Down" },
  left = { "Comma", "Gamepad_DPad_Left", "Gamepad_LeftStick_Left" },
  right = { "Period", "Gamepad_DPad_Right", "Gamepad_LeftStick_Right" },
  ok = { "Enter", "Gamepad_FaceButton_Bottom" },
  back = { "BackSpace", "Gamepad_FaceButton_Right" },
}
-- the rows on the F3 menu's grid: the characters, her voice, her blade, Apply, Close; tops at R0 + (i - 1) * RH
M.R0, M.RH, M.BH = 222, 58, 48
M.ROWS = {}
for _, c in ipairs(M.CHARS) do M.ROWS[#M.ROWS + 1] = { char = c } end
M.ROWS[#M.ROWS + 1] = { box = "voice", label = "Voice",
  help = "Her grunts, attack shouts, hurt and death sounds in the voice of the one she plays. Off: Eve's." }
M.ROWS[#M.ROWS + 1] = { box = "blade", label = "Blade", help = "Her own blade in place of Eve's sword. Off: Eve's sword." }
M.ROWS[#M.ROWS + 1] = { apply = true, label = "Apply" }
M.ROWS[#M.ROWS + 1] = { close = true, label = "Close", help = "Closes the menu. A pick not applied is dropped." }
for i, row in ipairs(M.ROWS) do row.y = M.R0 + (i - 1) * M.RH end
M.HELP_Y = M.R0 + 12 * M.RH + 14 -- (the F3 menu's: under its 12 rows)
M.VC = 945                        -- the values' middle
M.PAD = { "Gamepad_LeftShoulder", "Gamepad_RightShoulder", "Gamepad_RightThumbstick" } -- settings.menuPad's default
M.nav = {} -- the arrow keys pressed since the menu last looked (main.lua's binds)
M.state = { open = false, sel = 1, held = {}, toggled = 0 }
M.tex = {}
M.keyOf = {} -- (a key's name -> its FKey, made once)
M.PIC_RETRY = 3

local function read(p) local f = io.open(p, "r"); if not f then return nil end; local s = f:read("a"); f:close(); return s end
local function write(p, s) local f = io.open(p, "w"); if f then f:write(s); f:close() end end

function M.init(c)
  ctx, log, try, valid = c, function(s) c.log("menu: " .. s) end, c.try, c.valid
  os.remove(OK)
  os.remove(ANS)
end

-- ---- the text: StellarBladePlayAs's DLL hooked onto SBSnapShot (asked once its UFunction is there, answered within 0.25 s) ----
local text = { hooked = nil, asked = nil, by = nil }
local function cdo()
  if not valid(text.cdo) then text.cdo = try(function() return StaticFindObject(M.CDO) end) end
  return valid(text.cdo) and text.cdo or nil
end
-- every tick until it answers (or 5 s with none: the DLL isn't there)
function M.hook_tick()
  if text.hooked ~= nil then return end
  local r = read(OK)
  if r then
    text.hooked = r:sub(1, 2) == "ok"
    log("StellarBladePlayAsText: " .. r)
    return
  end
  if not text.asked then
    local fn = try(function() return StaticFindObject(M.HOOK_FN) end)
    local a = valid(fn) and try(function() return fn:GetAddress() end)
    if not a then return end
    write(HOOK, string.format("%x", a))
    text.asked = os.clock()
  elseif os.clock() - text.asked > 5 then
    text.hooked = false
    log("StellarBladePlayAsText: no answer in 5 s (its DLL not installed, or UE4SS didn't load it)")
  end
end
local ftextMissing
local function ftext_missing()
  if ftextMissing ~= nil then return ftextMissing end
  ftextMissing = false
  local f = io.open("ue4ss/UE4SS.log", "r")
  if not f then return false end
  for line in f:lines() do
    if line:find("Failed to find FText::FText", 1, true) then ftextMissing = true; break end
  end
  f:close()
  return ftextMissing
end
-- "dll", "ue4ss" or nil (neither: no menu)
local function text_by()
  if text.by ~= nil then return text.by or nil end
  if text.hooked == nil then return nil end -- (not known yet: asked again at the next open)
  local r
  if text.hooked and cdo() then
    os.remove(ANS)
    try(function() cdo():SBSnapShot("T?") end)
    r = read(ANS)
  end
  local fn = try(function() return StaticFindObject("/Script/UMG.TextBlock:SetText") end)
  text.setText = valid(fn) and try(function() return fn:GetAddress() end) or nil
  if r == "ok" and text.setText then text.by = "dll"
  elseif not ftext_missing() then text.by = "ue4ss"
  else text.by = false end
  log(string.format("its text by %s (StellarBladePlayAsText: %s)", text.by or "nothing", tostring(r or "not hooked")))
  return text.by or nil
end
M.text_by = text_by
local function set_text(tb, s)
  s = tostring(s or "")
  if text.by == "dll" then
    local a = try(function() return tb:GetAddress() end)
    local c = cdo()
    if a and c then try(function() c:SBSnapShot(string.format("T%x,%x;%s", a, text.setText, s)) end) end
  else
    try(function() tb:SetText(FText(s)) end)
  end
end

-- ---- widgets ----
local function cls(p)
  local c = StaticFindObject(p)
  if not valid(c) then error("no class " .. p) end
  return c
end
-- layout units: 1920 x 1080 fitted into the viewport by its height on a wider screen; VW, VH: the viewport in them
local function viewport(gi)
  local K, VW, VH = 1.0, 1920, 1080
  try(function()
    local lib = StaticFindObject("/Script/UMG.Default__WidgetLayoutLibrary")
    local size, scale = lib:GetViewportSize(gi), lib:GetViewportScale(gi)
    if size.X > 0 and size.Y > 0 and scale > 0 then K = math.min(size.X / 1920, size.Y / 1080) / scale end
    if K < 0.5 or K > 4 then K = 1.0 end
    if size.Y > 0 and scale > 0 then VH = size.Y / scale / K end
    if size.X > 0 and scale > 0 then VW = size.X / scale / K end
  end)
  return K, VW, VH
end
local function font(path) local f = StaticFindObject(path); return valid(f) and f or nil end
-- a widget of its own on the viewport: box(), text() and place() on its canvas
local function stage(prefix)
  local gi = FindFirstOf("GameInstance")
  if not valid(gi) then error("no game instance") end
  local K, VW, VH = viewport(gi)
  local fallback = font(M.FONT)
  local s = { gi = gi, K = K, VW = VW, VH = VH, n = 0, mid = font(M.FONT_MID) or fallback, bold = font(M.FONT_BOLD) or fallback }
  local stamp = string.format("%d%04d", os.time(), math.random(0, 9999))
  s.w = StaticConstructObject(cls("/Script/UMG.UserWidget"), gi, FName(prefix .. stamp))
  local tree = StaticConstructObject(cls("/Script/UMG.WidgetTree"), s.w, FName(prefix .. "Tree"))
  s.w.WidgetTree = tree
  s.canvas = StaticConstructObject(cls("/Script/UMG.CanvasPanel"), tree, FName(prefix .. "Canvas"))
  tree.RootWidget = s.canvas
  function s.place(slot, x, y, ww, hh, ax, ay)
    slot:SetAnchors({ Minimum = { X = 0, Y = 0 }, Maximum = { X = 0, Y = 0 } })
    slot:SetAlignment({ X = ax or 0, Y = ay or 0 })
    slot:SetPosition({ X = x * K, Y = y * K })
    if ww then slot:SetAutoSize(false); slot:SetSize({ X = ww * K, Y = hh * K }) else slot:SetAutoSize(true) end
  end
  function s.box(x, y, ww, hh, r, g, b, a)
    s.n = s.n + 1
    local im = StaticConstructObject(cls("/Script/UMG.Image"), tree, FName(prefix .. "Img" .. s.n))
    local slot = s.canvas:AddChildToCanvas(im)
    s.place(slot, x, y, ww, hh)
    im:SetColorAndOpacity({ R = r, G = g, B = b, A = a })
    return im, slot
  end
  -- o: font, wrap (layout units), boxw + just (1 centred, 2 right in a box that wide), spacing, mid (y is the line's
  -- middle), centre (x is its middle)
  function s.text(x, y, size, str, o)
    o = o or {}
    s.n = s.n + 1
    local tb = StaticConstructObject(cls("/Script/UMG.TextBlock"), tree, FName(prefix .. "Txt" .. s.n))
    if o.mid then y = y + size / 12 end
    s.place(s.canvas:AddChildToCanvas(tb), x, y, o.boxw, o.boxw and size * 1.8, o.centre and 0.5, o.mid and 0.5)
    try(function()
      local f = tb.Font
      local fo = o.font or s.mid
      if fo then f.FontObject = fo end
      f.Size = math.floor(size * K + 0.5)
      if o.spacing then f.LetterSpacing = o.spacing end
    end)
    if o.wrap then try(function() tb.WrapTextAt = o.wrap * K; tb.AutoWrapText = false end) end
    if o.just then
      if not try(function() tb:SetJustification(o.just); return true end) then try(function() tb.Justification = o.just end) end
    end
    set_text(tb, str)
    return tb
  end
  return s
end
local function tint(tb, r, g, b, a)
  try(function() tb:SetColorAndOpacity({ SpecifiedColor = { R = r, G = g, B = b, A = a or 1 }, ColorUseRule = 0 }) end)
end
local function show(x, on) try(function() x:SetRenderOpacity(on and 1 or 0) end) end
local function show_all(list, on) for _, x in ipairs(list) do show(x, on) end end

local function build()
  log("making it")
  local s = stage("StellarBladePlayAs_Menu_")
  local box, text = s.box, s.text
  local VW, VH = s.VW, s.VH
  -- a focus box: white, a blue glow round it (as the game's Slot_Focus)
  local function focus(x, y, ww, hh)
    local parts = {}
    for _, gl in ipairs({ { 8, 0.10 }, { 5, 0.22 }, { 2, 0.5 } }) do
      parts[#parts + 1] = box(x - gl[1], y - gl[1], ww + 2 * gl[1], hh + 2 * gl[1], 0.02, 0.22, 0.75, gl[2])
    end
    parts[#parts + 1] = box(x, y, ww, hh, 1, 1, 1, 1)
    return parts
  end
  -- the backdrop, the F3 menu's: near black, lighter blue-grey to the right, darker to the bottom, the faint crosses
  -- of the game's screen down the left
  box(0, 0, VW, VH, 0.004, 0.006, 0.009, 0.985)
  for i = 0, 39 do
    box(880 + i * (VW - 880) / 40, 0, (VW - 880) / 40 + 1, VH, 0.03, 0.045, 0.065, ((i + 1) / 40) ^ 1.6 * 0.6)
  end
  for i = 0, 9 do
    box(0, VH - 170 + i * 17, VW, 18, 0, 0, 0, (i + 1) / 10 * 0.55)
  end
  for _, c in ipairs({ { 96, 150 }, { 264, 186 }, { 96, 300 }, { 264, 312 }, { 96, 432 }, { 264, 440 }, { 96, 575 },
      { 264, 568 }, { 96, 720 }, { 264, 704 }, { 96, 852 }, { 264, 828 }, { 434, 210 }, { 434, 806 }, { 588, 800 } }) do
    box(c[1] - 30, c[2], 60, 1, 1, 1, 1, 0.06)
    box(c[1], c[2] - 30, 1, 60, 1, 1, 1, 0.06)
  end
  local ui = { s = s, w = s.w, rows = {}, K = s.K, gi = s.gi }
  -- her picture, right of the rows and under them (its slot sized to the one shown, render)
  ui.pic, ui.picSlot = box(1100, 70, 900, 900, 1, 1, 1, 1)
  show(ui.pic, false)
  tint(text(101, 92, 23, "Play As"), 0.716, 0.246, 0.034)
  tint(text(101, 196, 9, "STELLAR BLADE PLAY AS  " .. tostring(ctx.version or ""), { font = s.bold, spacing = 200 }), 0.25, 0.27, 0.3)
  -- the one tab, focused (as the F3 menu's open tab)
  focus(101, M.R0, 208, M.BH)
  tint(text(116, M.R0 + M.BH / 2, 17, "Characters", { font = s.bold, mid = true }), 0.022, 0.025, 0.05)
  -- the rows: label left, value centred, arrows either side of it on a focused box row
  local vc = M.VC
  for i, row in ipairs(M.ROWS) do
    local cy = row.y + M.BH / 2
    local r = { focus = focus(385, row.y, 790, M.BH),
      lab = text(400, cy, 17, row.char and row.char.name or row.label, { wrap = 340, mid = true }),
      val = text(vc, cy, 18, "", { font = s.bold, centre = true, mid = true }) }
    if row.box then
      r.la = text(vc - 170, cy, 18, "<", { font = s.bold, centre = true, mid = true })
      r.ra = text(vc + 170, cy, 18, ">", { font = s.bold, centre = true, mid = true })
    end
    ui.rows[i] = r
  end
  ui.help = text(400, M.HELP_Y, 15, "", { wrap = 780 })
  tint(ui.help, 0.32, 0.33, 0.35)
  -- the keys, bottom right: the game's icons (a white key cap with its text where one isn't in memory)
  local function icon_tex(path)
    local tex = StaticFindObject(M.ICONS .. path .. "." .. path:match("[^/]+$"))
    return valid(tex) and tex or nil
  end
  local function hints(list)
    local IS, GAP, KGAP, CAP, CW = 44, 30, 6, 30, 9
    local function caps_of(h)
      if type(h[3]) == "table" then return h[3] end
      return { h[3] }
    end
    local plan, width = {}, 0
    for i, h in ipairs(list) do
      local caps, keys, kw = caps_of(h), {}, 0
      for j, p in ipairs(h[1]) do
        local tex = icon_tex(p)
        local cap = caps[j] or "?"
        local w = tex and (CAP + 2) or math.max(CAP, #cap * CW + 14)
        keys[j] = { tex = tex, cap = cap, w = w }
        kw = kw + w + (j > 1 and KGAP or 0)
      end
      local lw = 10 + #h[2] * 10
      plan[i] = { keys = keys, kw = kw, lw = lw, g = i < #list and GAP or 0, name = h[2] }
      width = width + kw + lw + plan[i].g
    end
    local x, cy, out = VW - 90 - width, VH - 73, {}
    for _, pl in ipairs(plan) do
      for j, k in ipairs(pl.keys) do
        local made = false
        if k.tex then
          local im = box(x + k.w / 2 - IS / 2, cy - IS / 2, IS, IS, 1, 1, 1, 1)
          if try(function() im:SetBrushFromTexture(k.tex, false); return true end) then out[#out + 1] = im; made = true
          else show(im, false) end
        end
        if not made then
          local w = math.max(CAP, #k.cap * CW + 14)
          out[#out + 1] = box(x, cy - CAP / 2, w, CAP, 0.95, 0.95, 0.95, 1)
          local kt = text(x + w / 2, cy, 15, k.cap, { font = s.bold, centre = true, mid = true })
          tint(kt, 0.03, 0.035, 0.05)
          out[#out + 1] = kt
        end
        x = x + k.w + (j < #pl.keys and KGAP or 0)
      end
      out[#out + 1] = text(x + 10, cy, 17, pl.name, { font = s.bold, mid = true })
      x = x + pl.lw + pl.g
    end
    return out
  end
  ui.keys = {}
  -- (the keyboard's Exit: the menu's key, its icon when it is a plain F key, else a cap with its name)
  local mk = tostring(ctx.menuKey or "F4")
  for set, list in pairs(M.HINTS) do
    if set == "kb" then
      list = { list[1], list[2], { { "PC/KeyIcon_KeyBoard_" .. (mk:match("^F%d+$") or "None") }, "Exit", mk } }
    end
    ui.keys[set] = hints(list)
  end
  try(function() s.w:SetVisibility(3) end) -- not hit-testable: clicks reach the game's input, read in M.tick
  s.w:AddToViewport(970)
  log("made")
  return ui
end

-- her picture: found in memory, else loaded (not while the game may be loading: ctx.may_load); kept by its path,
-- found again once the engine let it go. One the game hasn't (Scarlet's without the NIKKE content) isn't asked again
-- A picture of your own, StellarBladePlayAs/portraits/<key>.png (or .jpg), goes in place of the game's: read by the engine's
-- ImportFileAsTexture2D (its size gives its shape), read again once the engine let it go
local function own_picture(c)
  for _, ext in ipairs({ "png", "jpg" }) do
    local path = DIR .. "portraits/" .. c.key .. "." .. ext
    local f = io.open(path, "rb")
    if f then
      f:close()
      local lib = try(function() return StaticFindObject("/Script/Engine.Default__KismetRenderingLibrary") end)
      local t = valid(lib) and try(function() return lib:ImportFileAsTexture2D(M.state.ui.gi, path) end)
      if valid(t) then
        local w = try(function() return t:Blueprint_GetSizeX() end)
        local h = try(function() return t:Blueprint_GetSizeY() end)
        c.ownAspect = (w and h and w > 0 and h > 0) and w / h or nil
        if not M.tex["+" .. c.key] then M.tex["+" .. c.key] = true; log(c.name .. "'s picture: " .. path) end
        return t
      end
      if not M.tex["-" .. c.key] then M.tex["-" .. c.key] = true; log(c.name .. "'s picture " .. path .. " couldn't be read: the game's") end
      return nil
    end
  end
end
-- a texture still the one kept for key (its name as it was found: the engine let one go and another object took its
-- place, and the picture showed blank, playtest) and with a size (one still streaming in has none)
local function tex_ok(t, key)
  if not valid(t) then return false end
  local n = try(function() return t:GetFName():ToString() end)
  return n ~= nil and n == M.texName[key] and (try(function() return t:Blueprint_GetSizeX() end) or 0) > 0
end
M.texName = {}
local function picture(c)
  local t = M.tex[c.key]
  if tex_ok(t, c.key) then return t end
  c.ownAspect = nil
  t = not M.tex["-" .. c.key] and own_picture(c)
  if t then M.tex[c.key], M.texName[c.key] = t, try(function() return t:GetFName():ToString() end); return t end
  t = try(function() return StaticFindObject(c.tex) end)
  -- (one in memory but not loaded through yet, the game still streaming it in, has no size: put on the picture it
  -- showed nothing, and counted as shown it was never looked for again, playtest. Loaded here, it is finished first)
  if valid(t) and (try(function() return t:Blueprint_GetSizeX() end) or 0) <= 0 then t = nil end
  -- (a load that found nothing is tried again PIC_RETRY s later: one asked while a level was coming in found nothing,
  -- and the picture never came back that session, playtest)
  local failed = M.tex["!" .. c.key]
  if not valid(t) and LoadAsset and ctx.may_load() and not (failed and os.clock() - failed < M.PIC_RETRY) then
    t = try(function() return LoadAsset(c.tex) end)
    if not valid(t) then
      M.tex["!" .. c.key] = os.clock()
      if not M.tex["?" .. c.key] then M.tex["?" .. c.key] = true; log(c.name .. "'s picture not found: " .. c.tex) end
    end
  end
  M.tex[c.key] = valid(t) and t or nil
  M.texName[c.key] = M.tex[c.key] and try(function() return t:GetFName():ToString() end) or nil
  if M.tex[c.key] and not tex_ok(t, c.key) then M.tex[c.key] = nil end
  return M.tex[c.key]
end

local function pending_changed()
  local s, set = M.state, ctx.settings
  return s.who ~= (set.who or "eve") or s.voice ~= (set.voice ~= false) or s.blade ~= (set.blade ~= false)
end
local function char_of(key) for _, c in ipairs(M.CHARS) do if c.key == key then return c end end end

local show_picture -- (below)
local function render()
  local s, ui = M.state, M.state.ui
  if not ui then return end
  local set = ctx.settings
  local live = pending_changed()
  for i, row in ipairs(M.ROWS) do
    local r, on = ui.rows[i], i == s.sel
    show_all(r.focus, on)
    local val = ""
    if row.char then
      val = row.char.key == (set.who or "eve") and "Playing" or row.char.key == s.who and "Picked"
        or (ctx.looks and ctx.looks.available(row.char.key) == false) and (ctx.looks.LOOKS[row.char.key].dlc and "Needs DLC" or "Not found") or ""
    elseif row.box then val = s[row.box] and "On" or "Off" end
    set_text(r.val, val)
    if r.la then show(r.la, on); show(r.ra, on) end
    if on then
      tint(r.lab, 0.022, 0.025, 0.05); tint(r.val, 0.022, 0.025, 0.05)
      if r.la then tint(r.la, 0.02, 0.32, 0.9); tint(r.ra, 0.02, 0.32, 0.9) end
    else
      -- (Apply with nothing to apply a shade dimmer, as the F3 menu's sub-settings)
      local c = row.apply and not live and 0.38 or 0.6
      tint(r.lab, c, c, c * 1.03); tint(r.val, 0.85, 0.85, 0.86)
    end
  end
  local row = M.ROWS[s.sel]
  local picked = char_of(s.who) or M.CHARS[1]
  local help
  if row.apply then
    help = live and ("Plays as " .. picked.name .. (s.voice and "" or ", with Eve's voice") .. (s.blade and "" or ", with Eve's sword") .. ". The rest of the game stays as it is.")
      or "Nothing to apply: that is what she is now."
  elseif row.char then
    help = row.char.about .. (row.char.key == (set.who or "eve") and "" or row.char.key == s.who and " Apply puts her on."
      or " Enter picks her, then Apply puts her on.")
  else help = row.help end
  set_text(ui.help, help)
  show_picture()
  for setn, list in pairs(ui.keys) do
    show_all(list, setn == (s.pad and ((ctx.settings.padIcons == "xbox") and "xbox" or "playstation") or "kb"))
  end
end
-- her picture: the name under the focus, else the one picked
show_picture = function()
  local s, ui = M.state, M.state.ui
  local row = M.ROWS[s.sel]
  local c = row.char or char_of(s.who) or M.CHARS[1]
  if s.shown ~= c.key or not tex_ok(ui.picTex, c.key) then
    local t = picture(c)
    if t and try(function() ui.pic:SetBrushFromTexture(t, false); return true end) then
      -- (900 high, its foot above the key hints, its middle at 1550: the album's square overlaps the rows' right end
      -- with its clear sides only, under them)
      local h = 900
      local w = h * (c.ownAspect or c.aspect)
      -- (a wide one of your own, a screenshot: 820 wide at most, as tall as that leaves it)
      if w > 820 then h, w = 820 / w * h, 820 end
      try(function()
        ui.picSlot:SetPosition({ X = (1550 - w / 2) * ui.K, Y = (ui.s.VH - h - 110) * ui.K })
        ui.picSlot:SetSize({ X = w * ui.K, Y = h * ui.K })
      end)
      show(ui.pic, true)
      ui.picTex, s.shown = t, c.key
    else
      show(ui.pic, false)
      ui.picTex, s.shown = nil, nil
    end
  end
end

-- ---- open, close, her input held ----
-- (asked each frame: the library and her controller kept while they are valid)
local function controller(pawn)
  if not valid(M.gs) then M.gs = StaticFindObject("/Script/Engine.Default__GameplayStatics") end
  local gs = M.gs
  if not (valid(M.pc) and M.pcPawn == pawn) then
    M.pc, M.pcPawn = valid(gs) and try(function() return gs:GetPlayerController(pawn, 0) end), pawn
  end
  return gs, M.pc
end
local function hold(pawn, on)
  local s = M.state
  local _, pc = controller(pawn)
  if on and not s.paused then
    s.paused = { pawn = pawn, pc = pc }
    if valid(pc) then
      try(function() pc:SetIgnoreMoveInput(true) end)
      try(function() pc:SetIgnoreLookInput(true) end)
      try(function() pawn:DisableInput(pc) end)
      s.paused.cursor = try(function() return pc.bShowMouseCursor end)
      try(function() pc.bShowMouseCursor = true end)
      local wbl = StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary")
      if valid(wbl) then try(function() wbl:SetInputMode_GameAndUIEx(pc, nil, 0, false) end) end
    end
  elseif not on and s.paused then
    local p = s.paused
    s.paused = nil
    if valid(p.pc) then
      try(function() p.pc:ResetIgnoreMoveInput() end)
      try(function() p.pc:ResetIgnoreLookInput() end)
      if valid(p.pawn) then try(function() p.pawn:EnableInput(p.pc) end) end
      try(function() p.pc.bShowMouseCursor = p.cursor == true end)
      local wbl = StaticFindObject("/Script/UMG.Default__WidgetBlueprintLibrary")
      if valid(wbl) then try(function() wbl:SetInputMode_GameOnly(p.pc) end) end
    end
  end
end
-- another mod's menu up (the Stellar Blade Gore mod's F3: its widget shown, hit-test invisible, while open): both would
-- hold her input and give it back as each closed
local function other_menu_open()
  local open = false
  try(function()
    for _, w in ipairs(FindAllOf("UserWidget") or {}) do
      local n = try(function() return w:GetFName():ToString() end) or ""
      if n:find("^SBGore_Menu_") and try(function() return w:IsInViewport() end) and try(function() return w:GetVisibility() end) == 3 then
        open = true
        break
      end
    end
  end)
  return open
end
function M.open(pawn)
  local s = M.state
  if s.open then return end
  if other_menu_open() then log("not opened: the Gore mod's F3 menu is open"); return end
  local ok = s.ui and valid(s.ui.w) and try(function() return s.ui.w:IsInViewport() end)
  if not ok and not text_by() then
    log(text.hooked == nil and "not made yet: StellarBladePlayAsText hasn't answered (a few seconds after the game starts)"
      or "not made: StellarBladePlayAsText can't set its text, and UE4SS didn't find the game's FText constructor; settings.lua's who still picks")
    return
  end
  if not ok then
    local built, ui = pcall(build)
    if not built then log("couldn't be made: " .. tostring(ui)); return end
    s.ui, s.shown = ui, nil
  else
    try(function() s.ui.w:SetVisibility(3) end)
  end
  local set = ctx.settings
  s.open, s.held, s.swallow = true, {}, true
  s.who, s.voice, s.blade = set.who or "eve", set.voice ~= false, set.blade ~= false
  for i, row in ipairs(M.ROWS) do if row.char and row.char.key == s.who then s.sel = i end end
  M.nav = {}
  hold(pawn, true)
  render()
  log("opened")
end
function M.close(pawn, why)
  local s = M.state
  if not s.open then return end
  s.open = false
  if s.ui and valid(s.ui.w) then try(function() s.ui.w:SetVisibility(1) end) end
  hold(pawn, false)
  log("closed" .. (pending_changed() and " (not applied: " .. tostring(s.who) .. ")" or "") .. (why and (", " .. why) or ""))
end
-- a new Eve (a level loaded): her old controller's hold is gone with her, the widgets with the level
function M.forget()
  local s = M.state
  s.open, s.paused, s.ui, s.shown = false, nil, nil, nil
  M.toast_ui = nil
end
function M.toggle(pawn, pad)
  local now = os.clock()
  if now - M.state.toggled < 0.3 then return end
  M.state.toggled = now
  if not M.state.open then M.state.pad = pad == true end
  if M.state.open then M.close(pawn) else M.open(pawn) end
end

local function apply()
  local s = M.state
  if not pending_changed() then return end
  ctx.apply(s.who, s.voice, s.blade, "the menu")
end
local function move(dir)
  local s = M.state
  s.sel = (s.sel - 1 + dir) % #M.ROWS + 1
  render()
end
local function step(dir)
  local s = M.state
  local row = M.ROWS[s.sel]
  if row.box then s[row.box] = not s[row.box]; render()
  elseif row.char then
    -- (on the names: the next or previous one, round)
    local i = s.sel
    repeat i = (i - 1 + dir) % #M.ROWS + 1 until M.ROWS[i].char
    s.sel = i
    render()
  end
end
local function press(pawn)
  local s = M.state
  local row = M.ROWS[s.sel]
  -- (a name: picked, the focus on to Apply)
  if row.char then
    s.who = row.char.key
    for i, r in ipairs(M.ROWS) do if r.apply then s.sel = i end end
  elseif row.box then s[row.box] = not s[row.box]
  elseif row.close then M.close(pawn); return
  else apply() end
  render()
end

-- the mouse: hover moves the focus (and shows the name under it), a click on a name picks it, on a box turns it, on
-- Apply applies
local function mouse(pawn, pc, down)
  local s, ui = M.state, M.state.ui
  M.wll = valid(M.wll) and M.wll or StaticFindObject("/Script/UMG.Default__WidgetLayoutLibrary")
  local p = valid(M.wll) and try(function() return M.wll:GetMousePositionOnViewport(ui.gi) end)
  if not p then return end
  local x, y = p.X / ui.K, p.Y / ui.K
  local moved = s.mx ~= nil and math.abs(x - s.mx) + math.abs(y - s.my) > 2
  s.mx, s.my = x, y
  local lmb = down("LeftMouseButton")
  local click = lmb and not s.lmb
  s.lmb = lmb
  local function just(k) return try(function() return pc:WasInputKeyJustPressed({ KeyName = FName(k) }) end) == true end
  local wheel = just("MouseScrollUp") and -1 or just("MouseScrollDown") and 1 or nil
  if (moved or click or wheel) and s.pad then s.pad = false; render() end
  if wheel then move(wheel); return end
  if not (moved or click) then return end
  for i, row in ipairs(M.ROWS) do
    if x >= 385 and x <= 1175 and y >= row.y and y <= row.y + M.BH then
      if s.sel ~= i then s.sel = i; render() end
      if click then
        if row.char then s.who = row.char.key
        elseif row.box then s[row.box] = not s[row.box]
        elseif row.close then M.close(pawn); return
        else apply() end
        render()
      end
      return
    end
  end
end

-- every tick of hers: the controller's open combo, and the menu's keys while it is open (a key held repeats)
function M.tick(pawn)
  local s = M.state
  M.toast_tick()
  local _, pc = controller(pawn)
  if not valid(pc) then return end
  -- (down, or pressed since the last frame: a tap that went down and up within one long frame, a hitch, was never
  -- seen down, and the controller's buttons seemed not to answer, Nexus report)
  local function down(name)
    local k = M.keyOf[name]
    if not k then k = { KeyName = FName(name) }; M.keyOf[name] = k end
    return try(function() return pc:IsInputKeyDown(k) or pc:WasInputKeyJustPressed(k) end) == true
  end
  -- (a settings.lua from before the menu has none: the default)
  local pad = ctx.settings.menuPad or M.PAD
  if type(pad) == "table" and #pad > 0 then
    local all = true
    for _, k in ipairs(pad) do if not down(k) then all = false; break end end
    if all and not s.padWas then M.toggle(pawn, true) end
    s.padWas = all
  end
  if not s.open then M.nav = {}; return end
  if not valid(s.ui and s.ui.w) then M.close(pawn, "its widget gone"); return end
  if not s.swallow then mouse(pawn, pc, down) end
  if #M.nav > 0 then
    local nav = M.nav
    M.nav = {}
    if s.pad then s.pad = false; render() end
    for _, d in ipairs(nav) do
      if d == "up" then move(-1) elseif d == "down" then move(1) elseif d == "left" then step(-1) else step(1) end
    end
  end
  local now = os.clock()
  for what, names in pairs(M.KEYS) do
    local on, padKey = false, nil
    for _, k in ipairs(names) do if down(k) then on = true; padKey = k:sub(1, 7) == "Gamepad"; break end end
    local h = s.held[what]
    if on and not h and padKey ~= s.pad then s.pad = padKey; render() end
    if not on then s.held[what] = nil
    elseif s.swallow and not h then s.held[what] = { next = math.huge } -- down as it opened: not a press
    elseif not h or now >= h.next then
      s.held[what] = { next = now + (h and 0.08 or 0.4) }
      if what == "up" then move(-1) elseif what == "down" then move(1)
      elseif what == "left" then step(-1) elseif what == "right" then step(1)
      elseif what == "ok" and not h then press(pawn)
      elseif what == "back" and not h then M.close(pawn); return end
    end
  end
  s.swallow = false
  -- her picture not there yet (not loaded while the game may be loading: Raven's stayed blank after a respawn,
  -- playtest), or the engine let the one shown go: looked for again twice a second
  if now >= (s.picNext or 0) then s.picNext = now + 0.5; show_picture() end
end
-- what was applied from elsewhere shown at once on an open menu
function M.refresh()
  local s = M.state
  if not s.open then return end
  -- (the focus left where it is: after Apply, on Apply)
  local set = ctx.settings
  s.who, s.voice, s.blade = set.who or "eve", set.voice ~= false, set.blade ~= false
  render()
end

-- ---- the toast: a line at the top of the screen for 2 s, faded out over the next one ----
function M.toast(str)
  if not text_by() then return end
  local t = M.toast_ui
  if not (t and valid(t.w) and try(function() return t.w:IsInViewport() end)) then
    local ok, s = pcall(function()
      local s = stage("StellarBladePlayAs_Toast_")
      s.bg = s.box(s.VW / 2 - 260, 70, 520, 56, 0.004, 0.006, 0.009, 0.85)
      s.line = s.box(s.VW / 2 - 260, 124, 520, 2, 0.716, 0.246, 0.034, 1)
      s.tb = s.text(s.VW / 2, 98, 22, "", { font = s.bold, centre = true, mid = true })
      try(function() s.w:SetVisibility(3) end)
      s.w:AddToViewport(980)
      return s
    end)
    if not ok then log("toast not made: " .. tostring(s)); return end
    M.toast_ui, t = s, s
  end
  set_text(t.tb, str)
  t.at = os.clock()
  try(function() t.w:SetRenderOpacity(1) end)
end
function M.toast_tick()
  local t = M.toast_ui
  if not (t and t.at) or not valid(t.w) then return end
  local age = os.clock() - t.at
  if age >= 3 then t.at = nil; try(function() t.w:SetRenderOpacity(0) end)
  elseif age > 2 then try(function() t.w:SetRenderOpacity(3 - age) end) end
end

return M
