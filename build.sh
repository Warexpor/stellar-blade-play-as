#!/usr/bin/env bash
# Build StellarBladePlayAs's DLL (its menu's text: native/playas.c; as the Gore mod's sbslice: clang + Rust's lld) and stage the
# mod, laid out like the game folder: build/stage/SB/Binaries/Win64/ue4ss/Mods/{StellarBladePlayAs,StellarBladePlayAsText}, zipped to
# build/StellarBladePlayAs.zip.
#   ./build.sh            build and stage
#   ./build.sh --install  and copy it into the game (not while it runs)
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
SB=$HERE/native
if [[ ${MSYSTEM:-} ]]; then
  LLD=$(command -v lld-link || true)
  [[ -n $LLD ]] || { echo "need lld-link (MSYS2 clang64) for linking"; exit 1; }
else
  LLD=$(ls -d "$HOME"/.rustup/toolchains/*/lib/rustlib/x86_64-unknown-linux-gnu/bin/rust-lld 2>/dev/null | head -1)
  [[ -x $LLD ]] || { echo "need rust-lld (rustup) for linking"; exit 1; }
fi
OUT=${SB_BUILD:-$HERE/build}
mkdir -p "$OUT"
for d in kernel32; do llvm-dlltool -m i386:x86-64 -d "$SB/$d.def" -l "$OUT/$d.lib"; done
clang --target=x86_64-pc-windows-msvc -O2 -ffreestanding -fno-builtin -fno-stack-protector -mno-stack-arg-probe \
  -Wall -Wextra -c "$HERE/native/playas.c" -o "$OUT/playas.obj"
if [[ ${MSYSTEM:-} ]]; then
  winout=$(cygpath -m "$OUT")
  MSYS2_ARG_CONV_EXCL='*' "$LLD" /dll /entry:DllMain /nodefaultlib /subsystem:windows "/out:$winout/main.dll" \
    "$winout/playas.obj" "$winout/kernel32.lib"
else
  "$LLD" -flavor link /dll /entry:DllMain /nodefaultlib /subsystem:windows "/out:$OUT/main.dll" \
    "$OUT/playas.obj" "$OUT/kernel32.lib"
fi
STAGE=$OUT/stage
MODS=$STAGE/SB/Binaries/Win64/ue4ss/Mods
rm -rf "$STAGE"; mkdir -p "$MODS/StellarBladePlayAs/Scripts" "$MODS/StellarBladePlayAs/portraits" "$MODS/StellarBladePlayAsText/dlls"
cp "$HERE"/Scripts/{main,looks,voice,menu}.lua "$MODS/StellarBladePlayAs/Scripts/"
# (--install keeps the player's own settings.lua)
cp "$HERE/Scripts/settings.lua" "$MODS/StellarBladePlayAs/Scripts/"
cp "$OUT/main.dll" "$MODS/StellarBladePlayAsText/dlls/main.dll"
touch "$MODS/StellarBladePlayAs/enabled.txt" "$MODS/StellarBladePlayAsText/enabled.txt"
cp "$HERE/README.md" "$STAGE/StellarBladePlayAs-README.md"
echo "Pictures of your own for the F4 menu: eve.png, tachy.png, raven.png or scarlet.png (or .jpg) here." > "$MODS/StellarBladePlayAs/portraits/README.txt"
rm -f "$OUT/StellarBladePlayAs.zip"; (cd "$STAGE" && zip -qr -X "$OUT/StellarBladePlayAs.zip" .)
echo "built $OUT/StellarBladePlayAs.zip"
if [[ ${1:-} == --install ]]; then
  # (the scripts must load, and read no global but Lua's and UE4SS's: a local used above its definition is a nil global
  # at run time, as the gore mod's install.sh checks)
  LUAC=luac
  command -v luac5.4 >/dev/null && LUAC=luac5.4
  for f in "$HERE"/Scripts/*.lua; do
    "$LUAC" -p "$f" || { echo "not installed: $f does not load"; exit 1; }
    bad=$("$LUAC" -l -p "$f" | grep -o 'GETTABUP.*_ENV "[A-Za-z_0-9]*"' | grep -o '"[^"]*"' | tr -d '"' | sort -u |
      grep -vxE 'assert|dofile|error|io|ipairs|math|next|os|pairs|pcall|print|require|select|setmetatable|getmetatable|string|table|tonumber|tostring|type|xpcall|FName|FText|LoadAsset|StaticFindObject|StaticConstructObject|FindFirstOf|FindAllOf|RegisterHook|RegisterKeyBind|LoopAsync|Key|ModifierKey' || true)
    [[ -z $bad ]] || { echo "not installed: $f reads undefined globals: $bad"; exit 1; }
  done
  if [[ ${MSYSTEM:-} ]]; then
    processes=$(MSYS2_ARG_CONV_EXCL='*' tasklist.exe /FI 'IMAGENAME eq SB-Win64-Shipping.exe' /NH) || { echo "could not check whether the game is running: not installed"; exit 1; }
    if grep -qi 'SB-Win64-Shipping.exe' <<< "$processes"; then echo "the game is running: not installed"; exit 1; fi
  else
    pgrep -af '[S]B-Win64-Shipping.exe SB' >/dev/null && { echo "the game is running: not installed"; exit 1; }
  fi
  GAME=${SB_GAME:-$HOME/.local/share/Steam/steamapps/common/StellarBlade}
  G=$GAME/SB/Binaries/Win64/ue4ss/Mods
  [[ -d $G ]] || { echo "no UE4SS Mods folder in $GAME"; exit 1; }
  KEEP=$(mktemp)
  # its old name (SBPlayAs): settings, pick and pictures moved over, its folders (and SBPlayAsWindow, its DLL before
  # the in-game menu) removed
  if [[ -d $G/SBPlayAs && ! -d $G/StellarBladePlayAs ]]; then
    mkdir -p "$G/StellarBladePlayAs/Scripts"
    [[ -f $G/SBPlayAs/Scripts/settings.lua ]] && cp "$G/SBPlayAs/Scripts/settings.lua" "$G/StellarBladePlayAs/Scripts/"
    [[ -f $G/SBPlayAs/choice.txt ]] && cp "$G/SBPlayAs/choice.txt" "$G/StellarBladePlayAs/"
    [[ -d $G/SBPlayAs/portraits ]] && cp -r "$G/SBPlayAs/portraits" "$G/StellarBladePlayAs/"
  fi
  rm -rf "$G/SBPlayAs" "$G/SBPlayAsText" "$G/SBPlayAsWindow"
  [[ -f $G/StellarBladePlayAs/Scripts/settings.lua ]] && cp "$G/StellarBladePlayAs/Scripts/settings.lua" "$KEEP"
  rm -rf "$G/StellarBladePlayAs/Scripts" "$G/StellarBladePlayAsText"
  cp -r "$MODS/StellarBladePlayAs" "$MODS/StellarBladePlayAsText" "$G/"
  [[ -s $KEEP ]] && cp "$KEEP" "$G/StellarBladePlayAs/Scripts/settings.lua"
  rm -f "$KEEP"
  echo "installed into $G"
fi
