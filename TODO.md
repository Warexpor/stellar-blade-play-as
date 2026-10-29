# To do

## After the Nexus reports (2026-10-29)

- Tachy's and Raven's faces: `its skin (slot ...) lit as Eve's` in the log; skin tone as bright as Eve's neck and body, no seam of colour at the neck, no Eve blood or makeup in odd places. Any `its skin NOT lit as Eve's` line.
- Stutter: play a few minutes as each; any `slow tick:` line says which part took the time. None and still stuttering: it's not this mod's tick.
- Controller: L1 + R1 + R3 opens it, Circle closes it, Cross on Close closes it.
- Tachy's hair: swinging with her head, not kicked running straight on, off her body; Raven's strands calm during a roll, swinging again after.
- With an outfit mod switching her outfit: the `put on her 4 times in 30 s by something else` line, no hitch each second.
- The menu's pictures: open it right after a level load and again later.
- Back to Eve after each, also after a cutscene, photo mode, a death and a level load as that character: her own outfit, hair, ponytails and earrings; any `found on her ... as the mod saw her anew` line, and no `new Eve` line without a level load.

## Second playtest

The sims pass (`test/run.sh`), and with the Gore mod its `native/sbslice/test/real/playas.sh` (its cuts and ragdoll fixes on these characters' meshes and physics assets). F4 (its menu: `menu:` lines), its `look:` and `voice:` lines in `StellarBladePlayAs/stellarbladeplayas.log`.

Seen in the first playtests (2026-10-28, all fixed since, see the changelog): the blade hidden mid-swing and standing in her hair after a cutscene, Eve's hairpin on Tachy, Raven with Eve's face and stiff hair, no Raven picture after a respawn, a crash when Raven's suit went back on over a fresh Gore mod cut. To look at next:

- Back to Eve after each of them, with a shield-break outfit mod's torn suit put on meanwhile too: her outfit whole, in its own materials (`(the game put ... on her: hers for Eve)`, any `a material of the last look on her again` line).
- Scarlet: her face on (seam, eyes), her blade along her hand as Eve holds hers (drawn, mid-combo, after a dodge), Eve's sword straight again after.
- Raven's hair on her back and legs, not through them (`touching 10 capsules on her body`): any jitter or a strand flung off as it settles at spawn, running, rolling.
- Tachy's hair: `look: Tachy's hair: at her head, ... strand bones swung by spring` and `its hair's sections hidden (4, 5)`. It swings (no physics now: the mod swings its bones itself), rests on her back, no second (still) copy of her hair on her body, no seam where it meets her head. With the Gore mod: a head cut and her death ragdoll with it (a cut-off head showing her hidden hair again would be the Gore mod drawing hidden sections).
- Raven's hair: calmer now (damping 2, 12 on every strand, `hairDamping` 100). Still too lively or too stiff: `hairDamping` (higher calms it), `hairSpring` in settings.lua. Any `put back as made` lines.
- Scarlet's hair: `look: Scarlet: ... hair EVE_HR_Nikke_01` (no `AnimBP NOT found`) and `its hair's sections hidden (3, 4, 5)`. Her hair, hat and fur swing; none of her body's own still copy showing; the hairstyle sits right on her head. Back to Eve: Eve's own hair.
- Raven's face at Eve's neck: the seam, the size, eyes and mouth still (it takes no expressions); with the Gore mod, her head off.
- The blade: `look: blade on Weapon: not on her head (shown)` and `on SC_SwordingPoint: on her head (put away: hidden)`; any other socket it is logged on. In a cutscene: the blade and the hairpin hidden.
- An outfit change and a camp rest while on.
- With the Gore mod and a shield-break outfit mod: an arm off at low HP as Raven (`look: a part of her is off ...`, then `whole again` after the rest), no crash.
- The F4 menu: every picture there each time it opens, also right after a respawn or level load (sharp, placed right on 16:9 and 21:9), the key icons, the mouse and the controller combo, her input back on closing; the toast on Apply.
- The voice: Eve's back on picking Eve, after a death and a level load too; any hitch as it swaps.
