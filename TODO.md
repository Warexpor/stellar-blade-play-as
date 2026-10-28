# To do

## First playtest (untried in game)

The sims pass (`test/run.sh`), and with the Gore mod its `native/sbslice/test/real/playas.sh` (its cuts and ragdoll fixes on these characters' meshes and physics assets). Nothing of it seen in game yet. F2 (its menu: `menu:` lines), its `look:` and `voice:` lines in `StellarBladePlayAs/stellarbladeplayas.log`.

- Tachy's hair physics on Eve's Blueprint (her hair bones may hang stiff), Raven's hair on master pose (its own bones at their reference pose), Scarlet with the DLC, the blades in her hand (does a blade on its own skeleton show unfolded and on her hand socket?), an outfit change and a camp rest while on.
- Their outfits in their own materials (no glow, nothing of Eve's outfit left; `look: her slots:` lists what is in each slot), the blade hidden in her hairpin and shown at once when drawn.
- The F2 menu: its text (`menu: StellarBladePlayAsText: ok patched`, `its text by dll`), the pictures (sharp, placed right on 16:9 and 21:9), the key icons, the mouse and the controller combo, her input back on closing; the toast on Shift+F2.
- The voice: her attack and hurt lines in Tachy's, Raven's and Scarlet's voice (`voice: tachy's voice on N recording slot(s) of M of Eve's cues`), Eve's back on picking Eve, after a death and a level load too; any hitch as it swaps.
- Moving over from `SBPlayAs`: the pick kept, the log's line while the old folders are still there.
- With the Gore mod: a cut and her ragdoll as each (Raven's hair off with her head, Scarlet's head cut with her body), the Gore mod's death cry in her voice.
