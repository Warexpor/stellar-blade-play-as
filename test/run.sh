#!/usr/bin/env bash
# The mod's Lua against a made-up game (test/fake.lua, copied from the Stellar Blade Gore mod's ue4ss/test): each scenario (sim_*.lua) prints PASS or
# FAIL lines.
#   test/run.sh [scenario...]   scenarios: looks, voice, main; default all (main runs in a scratch game folder)
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
FAKE=$HERE
SEL=("$@"); [[ ${#SEL[@]} -eq 0 ]] && SEL=(looks voice main)
fail=0
for s in "${SEL[@]}"; do
  d=${TMPDIR:-/tmp}/stellarbladeplayas-sim/$s
  rm -rf "$d"; mkdir -p "$d/ue4ss/Mods/StellarBladePlayAs"
  cp -r "$HERE/../Scripts" "$d/ue4ss/Mods/StellarBladePlayAs/Scripts"
  r=$(cd "$d" && SB_SCRIPTS="ue4ss/Mods/StellarBladePlayAs/Scripts/" LUA_PATH="$FAKE/?.lua;;" lua5.4 "$HERE/sim_$s.lua" 2>&1) || true
  echo "$r" | sed "s/^/$s: /"
  echo "$r" | grep -q '^PASS$' || fail=1
done
exit $fail
