#!/usr/bin/env bash
set -euo pipefail
export PATH="/clang64/bin:/usr/bin:$PATH"
ROOT=$(cd "$(dirname "$0")/.." && pwd)
export SB_BUILD="$ROOT/.cache/windows/build"
[[ -n ${SB_GAME:-} ]] && export SB_GAME=$(cygpath -u "$SB_GAME")
cd "$ROOT"
case "${1:-build}" in
  build)         exec bash build.sh ;;
  test)          exec bash test/run.sh ;;
  package)       exec bash package.sh ;;
  check-package) export SB_RELEASE="$ROOT/.cache/windows/package-check"; exec bash package.sh ;;
  install)       exec bash build.sh --install ;;
  *) echo "unknown action: $1" >&2; exit 2 ;;
esac
