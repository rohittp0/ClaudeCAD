#!/bin/bash
# check-deps.sh — Verify 3D modeling tool dependencies are available
# Runs on SessionStart; warns but never blocks.

missing=()

if ! command -v openscad &>/dev/null; then
  missing+=("openscad")
fi

if ! command -v admesh &>/dev/null; then
  missing+=("admesh")
fi

if [ ${#missing[@]} -eq 0 ]; then
  echo '{"systemMessage": "ClaudeCAD: openscad and admesh are available."}'
  exit 0
fi

tools_list=$(printf ", %s" "${missing[@]}")
tools_list="${tools_list:2}"

cat <<EOF
{"systemMessage": "ClaudeCAD: The following tools are NOT installed: ${tools_list}. The printable skill requires these for model validation. Install with: brew install ${tools_list} (macOS) or apt install ${tools_list} (Linux)."}
EOF

exit 0
