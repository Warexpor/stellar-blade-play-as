# Stellar Blade Play As

Play Stellar Blade as Tachy, Raven or Scarlet. Pick her in an in-game menu (F2) built like the Stellar Blade Gore mod's F3 menu (the game's own settings screen), with the game's own art of each character beside the list. Eve wears that character's body, face or hair (in its own materials, Eve's outfit accessories hidden), and her blade; with the sword folded away, that blade is hidden (it has no folded form for Eve's hairpin). Eve's grunts, attack shouts, hurt sounds and death cry are replaced with that character's own recordings from the game. Everything else is still Eve's: her moves, skills, combos, and physics. Needs [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) for Stellar Blade. Works on its own or alongside the Stellar Blade Gore mod.

<!-- install -->
**Installing:** extract the zip into the game's folder (`StellarBlade/`), so `StellarBladePlayAs` and `StellarBladePlayAsText` land in `SB/Binaries/Win64/ue4ss/Mods`. **Uninstalling:** delete those two folders. **Had it under its old name, SBPlayAs?** Delete `SBPlayAs`, `SBPlayAsText` (and `SBPlayAsWindow`, if there) from `Mods`; your pick is taken over from the old folder's `choice.txt`, and the log says if the old one is still installed (the two fight over her look).

| Key | What it does |
|---|---|
| F2 | Opens or closes the Play As menu. Up/Down goes through the characters, her picture on the right. Enter picks one ("Picked") and moves to Apply; Enter on Apply puts her on. Left/Right (or < and >) turns Her Voice and Her Blade on or off, also applied by Apply. Backspace or F2 closes; a pick not applied is dropped. The mouse works too: a click picks a name, turns a box, or applies |
| LB + RB + R3 | The same menu on a controller (`menuPad`): D-pad, A to pick and apply, B to close. Its button icons are PlayStation's or Xbox's (`padIcons`) |
| Shift+F2 | Switches to the next character without the menu (a line at the top of the screen says who) |

| Character | What she wears | Her blade | Her voice |
|---|---|---|---|
| Tachy | Her own body, hair and face (the beach-scene Tachy, built on Eve's skeleton) | Tachy's sword | Tachy's attack, hurt, breath and death lines |
| Raven | Her suit and her own hair. Eve's face stays, because the game has no Raven head for Eve's skeleton | Raven's blade | Raven's lines. Raven has no death line in the game, so her heaviest hurt screams play instead |
| Scarlet | Her whole body, head and hair. Needs the NIKKE collaboration content | Scarlet's sword | Scarlet's lines, including her own death lines |

Your pick, Her Voice and Her Blade are saved in `StellarBladePlayAs/choice.txt` and come back the next time you start the game. Defaults and keys are set in `StellarBladePlayAs/Scripts/settings.lua`. The game's voice volume slider controls her voice as usual. The voice follows the game's voice language as long as the game ships that character's lines in it.

**Your own pictures:** put a `.png` or `.jpg` named `eve`, `tachy`, `raven` or `scarlet` in `StellarBladePlayAs/portraits/` (for example `portraits/eve.png`, a photo-mode shot of Eve in her default suit) and the menu shows it in place of the game's. A cut-out with a transparent background looks best; a screenshot works too. The log says when one is used or can't be read.

**The menu's text** is set by `StellarBladePlayAsText` (its DLL), because UE4SS can't make text in this game. Without it the menu doesn't open (the log says why) and Shift+F2 still works. It hooks a cheat function the gore mod doesn't use, so the two never touch.

**What changes:** while she plays as someone else, the game's outfit menu has no effect, because her look is set again within a second. Pick Eve to get her outfit back. Her moves, cutscene voice, social lines and fishing lines stay Eve's.

**With the Stellar Blade Gore mod:** F2 doesn't open over its F3 menu. The cuts, struggle and dead face work on her as they do on Eve. The gore mod's own death cry and its breaths and moans after death are played in the voice of the character she looks like. Raven's hair comes off with her head.

**With other character or outfit mods:** a mod that changes Eve's body, face or hair will fight with this one while you play as someone other than Eve. Pick Eve to give it back. The log is `StellarBladePlayAs/stellarbladeplayas.log`.
<!-- /install -->

Built with `./build.sh` (clang and Rust's lld; the DLL is `native/playas.c`): `build/StellarBladePlayAs.zip`, `./build.sh --install` to copy it into the game (keeping your `settings.lua`, and moving an `SBPlayAs` install over). Sims: `test/run.sh` (a made-up game, `test/fake.lua`, copied from the [Stellar Blade Gore mod](https://github.com/Warexpor/stellar-blade-gore-mod)'s tests).

With the Gore mod, its own tests also cut these characters' meshes and run its ragdoll fixes on their physics assets: `native/sbslice/test/real/playas.sh` there.

License: GPL-3.0 (`LICENSE`).

How the voice works: the game voices Eve through SoundCues (`Sound/Voice/PC/eve_vo_*_Cue`), each a random pick of recordings. Each cue keeps its graph. Only the recording on each of its slots is swapped for one of the other character's, of the same kind: a light attack for a light attack, a heavy hit for a heavy hit, death for death. Eve's are put back by their asset paths. The cue's volume, range and sound class stay Eve's.
