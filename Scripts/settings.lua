-- StellarBladePlayAs settings. Edit and save, then restart the game. What you pick in game (the F4 menu)
-- is kept in StellarBladePlayAs/choice.txt and wins over who, voice and blade here; delete that file to start from these again.
return {
  who = "eve",            -- eve, tachy, raven, scarlet (needs the NIKKE content)
  voice = true,           -- her grunts, attack shouts, hurt and death sounds in the one she plays (false: Eve's)
  voiceVolume = 1.5,      -- their recordings are quieter than Eve's: her voice cues this much louder while theirs is on
  blade = true,           -- her own blade in place of Eve's sword (false: Eve's sword)
  menuKey = "F4",         -- opens and closes the in-game menu (UE4SS key names: F1-F12, HOME, INS, ...)
  -- the menu on the controller, all held together (the Gore mod's F3 menu is LB + RB + L3)
  menuPad = { "Gamepad_LeftShoulder", "Gamepad_RightShoulder", "Gamepad_RightThumbstick" },
  padIcons = "playstation", -- the menu's controller button icons: "playstation" or "xbox"
  -- Raven's and Tachy's hair: how hard each strand is pulled back to its shape, and how fast its swing dies down
  hairSpring = 3000,
  hairDamping = 100,
}
