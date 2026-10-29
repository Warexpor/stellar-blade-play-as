# Stellar Blade Play As

Play Stellar Blade as Tachy, Raven or Scarlet. Pick her in an in-game menu (F4) built like the Stellar Blade Gore mod's F3 menu (the game's own settings screen), with the game's own art of each character beside the list. Eve wears that character's body, face or hair (in its own materials, Eve's outfit accessories hidden), and her blade; with the sword put away, that blade is hidden (it has no folded form for Eve's hairpin), and so is Eve's hairpin. Eve's grunts, attack shouts, hurt sounds and death cry are replaced with that character's own recordings from the game. Everything else is still Eve's: her moves, skills, combos, and physics. Needs [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) for Stellar Blade. Works on its own or alongside the Stellar Blade Gore mod.

Version 0.2.1. See the [changelog](CHANGELOG.md).

<!-- install -->
## Install

You need the game on Steam (Windows, Linux or Steam Deck). **The game folder** below is `StellarBlade`, the one with `SB` in it: in Steam, right-click Stellar Blade > Manage > Browse local files.

1. **UE4SS** (skip if another mod already had you install it). Download `UE4SS_v3.1.0-6.zip` from [Chrisr0/RE-UE4SS](https://github.com/Chrisr0/RE-UE4SS/releases/tag/3.1.0-6), the Stellar Blade build (the regular UE4SS won't work). The Nexus "SB UE4SS" build ([mod 2952](https://www.nexusmods.com/stellarblade/mods/2952), 1.3) works too. Open it, go into its `UE4SS_v3.1.0-6` folder, and copy `dwmapi.dll` and the `ue4ss` folder into `StellarBlade/SB/Binaries/Win64/`, next to `SB-Win64-Shipping.exe`.
2. **This mod.** Extract `StellarBladePlayAs-0.2.1.zip` straight into the game folder, merging folders when asked, so `StellarBladePlayAs` and `StellarBladePlayAsText` land in `SB/Binaries/Win64/ue4ss/Mods`.
3. **Linux / Steam Deck only:** in Steam, Stellar Blade > Properties > Launch Options, put `WINEDLLOVERRIDES="dwmapi=n,b" %command%`. (Without it Proton ignores UE4SS.) **On Windows leave Launch Options empty**: that line is for Proton and Windows can't run it.

Start the game and press F4. To check it loaded, open `SB/Binaries/Win64/ue4ss/Mods/StellarBladePlayAs/stellarbladeplayas.log`: it has a line `StellarBladePlayAs 0.2.1 loaded: playing as ...`. **Updating:** extract the new zip over the old one; your pick stays, but `settings.lua` is the new one's (copy your edits back over). **Uninstalling:** delete those two folders. **Had it under its old name, SBPlayAs?** Delete `SBPlayAs`, `SBPlayAsText` (and `SBPlayAsWindow`, if there) from `Mods`; your pick is taken over from the old folder's `choice.txt`, and the log says if the old one is still installed (the two fight over her look).

| Key | What it does |
|---|---|
| F4 | Opens or closes the Play As menu. Up/Down goes through the characters, her picture on the right. Enter picks one ("Picked") and moves to Apply; Enter on Apply puts her on. Left/Right (or < and >) turns Voice and Blade on or off, also applied by Apply. Backspace or F4 closes; a pick not applied is dropped. The mouse works too: a click picks a name, turns a box, or applies |
| L1 + R1 + R3 (Xbox: LB + RB + R3) | The same menu on a controller (`menuPad`), the shoulder buttons, not the triggers, held with the right stick pressed in: D-pad, Cross / A to pick and apply, Circle / B to close. Its button icons are PlayStation's or Xbox's (`padIcons`) |

| Character | What she wears | Her blade | Her voice |
|---|---|---|---|
| Tachy | Her own body, hair and face (the beach-scene Tachy, built on Eve's skeleton), her hair swinging with physics and resting on her back | Tachy's sword | Tachy's attack, hurt, breath and death lines |
| Raven | Her suit, her face and her own long hair, its strands swinging with physics and resting on her back and legs. Her face doesn't take Eve's expressions | Raven's blade | Raven's lines. Raven has no death line in the game, so her heaviest hurt screams play instead |
| Scarlet | Her whole body and face, her skirt, tail and straps swinging as on the game's Scarlet outfit for Eve, and her hair and hat as the NIKKE content's Scarlet hairstyle for Eve, swinging as it does on Eve. Needs the NIKKE collaboration content: without it her row says "Needs DLC", picking her changes nothing; Tachy and Raven are the base game's | Scarlet's sword | Scarlet's lines, including her own death lines |

Your pick, Voice and Blade are saved in `StellarBladePlayAs/choice.txt` and come back the next time you start the game. Defaults and keys are set in `StellarBladePlayAs/Scripts/settings.lua`. The game's voice volume slider controls her voice as usual; the others' recordings are quieter than Eve's, so her voice plays 1.5 times as loud while it is theirs (`voiceVolume` in settings.lua: higher is louder, 1 as recorded). The voice follows the game's voice language as long as the game ships that character's lines in it.

**Your own pictures:** put a `.png` or `.jpg` named `eve`, `tachy`, `raven` or `scarlet` in `StellarBladePlayAs/portraits/` (for example `portraits/eve.png`, a photo-mode shot of Eve in her default suit) and the menu shows it in place of the game's. A cut-out with a transparent background looks best; a screenshot works too. The log says when one is used or can't be read.

**The menu's text** is set by `StellarBladePlayAsText` (its DLL), because UE4SS can't make text in this game. Without it the menu doesn't open (the log says why); `who` in `settings.lua` still picks. It hooks a cheat function the gore mod doesn't use, so the two never touch.

**What changes:** while she plays as someone else, the game's outfit menu has no effect, because her look is set again within a second. Pick Eve to get her outfit back. Her moves, cutscene voice, social lines and fishing lines stay Eve's.

**With the Stellar Blade Gore mod:** F4 doesn't open over its F3 menu. The cuts, struggle and dead face work on her as they do on Eve. The gore mod's own death cry and its breaths and moans after death are played in the voice of the character she looks like. Raven's hair comes off with her head. While a part of her is off, nothing of her look is swapped (another mod putting an outfit on her then, as one that tears her suit when her shield breaks, keeps it till she is whole).

**With other character or outfit mods:** a mod that changes Eve's body, face or hair will fight with this one while you play as someone other than Eve. When something puts its own mesh on her four times in 30 s, this mod leaves it on for a minute instead of swapping back each time (each swap is a hitch; the log says so). Pick Eve to give it back. Move-set mods (new stances, combos, skills, such as ScarletRavenStances) change her moves, not her look or voice, and work alongside this one. The log is `StellarBladePlayAs/stellarbladeplayas.log`.
<!-- /install -->

Built with `./build.sh` (clang and Rust's lld; the DLL is `native/playas.c`): `build/StellarBladePlayAs.zip`, `./build.sh --install` to copy it into the game (keeping your `settings.lua`, and moving an `SBPlayAs` install over). `./package.sh` makes the release zip, `release/StellarBladePlayAs-<version>.zip` (players get the README's install part and the license). Sims: `test/run.sh` (a made-up game, `test/fake.lua`, copied from the [Stellar Blade Gore mod](https://github.com/Warexpor/stellar-blade-gore-mod)'s tests).

With the Gore mod, its own tests also cut these characters' meshes and run its ragdoll fixes on their physics assets: `native/sbslice/test/real/playas.sh` there.

License: GPL-3.0 (`LICENSE`).

How the voice works: the game voices Eve through SoundCues (`Sound/Voice/PC/eve_vo_*_Cue`), each a random pick of recordings. Each cue keeps its graph. Only the recording on each of its slots is swapped for one of the other character's, of the same kind: a light attack for a light attack, a heavy hit for a heavy hit, death for death. Eve's are put back by their asset paths. The cue's range and sound class stay Eve's; its volume is raised by `voiceVolume` while the recordings are another's.
