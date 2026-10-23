#!/bin/bash
set -euo pipefail
TARGET="${1:?Install directory required}"
mkdir -p "$TARGET"
command -v git >/dev/null || { echo "Git is required" >&2; exit 1; }
PYTHON=""
for CANDIDATE in /opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3; do
  if [[ -x "$CANDIDATE" ]] && "$CANDIDATE" -m venv --help >/dev/null 2>&1; then
    PYTHON="$CANDIDATE"
    break
  fi
done
[[ -n "$PYTHON" ]] || { echo "Python 3 with venv needed (install with Homebrew)" >&2; exit 1; }
if [[ ! -f "$TARGET/DawVert/dawvert_cmd.py" ]]; then
  git clone --depth=1 https://github.com/DawVert/DawVert.git "$TARGET/DawVert"
fi
if [[ ! -x "$TARGET/venv/bin/python3" ]]; then
  "$PYTHON" -m venv "$TARGET/venv"
fi
"$TARGET/venv/bin/python3" -m pip install -r "$TARGET/DawVert/requirements.txt"
echo "Engine installed"
