-- StellarBladePlayAs settings. Edit and save, then restart the game. What you pick in game (the F2 menu, the next-character key)
-- is kept in StellarBladePlayAs/choice.txt and wins over who, voice and blade here; delete that file to start from these again.
return {
  who = "eve",            -- eve, tachy, raven (her suit and hair, Eve's face), scarlet (needs the NIKKE content)
  voice = true,           -- her grunts, attack shouts, hurt and death sounds in the one she plays (false: Eve's)
  blade = true,           -- her own blade in place of Eve's sword (false: Eve's sword)
  menuKey = "F2",         -- opens and closes the in-game menu (UE4SS key names: F1-F12, HOME, INS, ...)
  nextKey = "F2",         -- with Shift: the next character, no menu
  -- the menu on the controller, all held together (the Gore mod's F3 menu is LB + RB + L3)
  menuPad = { "Gamepad_LeftShoulder", "Gamepad_RightShoulder", "Gamepad_RightThumbstick" },
  padIcons = "playstation", -- the menu's controller button icons: "playstation" or "xbox"
}
