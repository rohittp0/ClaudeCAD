#!/bin/bash
# validate-on-stop.sh — Auto-validate .scad files modified in the current session
# Runs on Stop; reports results but never blocks.

VALIDATE_SCRIPT="${CLAUDE_PLUGIN_ROOT}/skills/printable/scripts/validate-model.sh"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"

# Find .scad files modified in the last hour
SCAD_FILES=$(find "$PROJECT_DIR" -maxdepth 2 -name "*.scad" -newer "$PROJECT_DIR/.claude" -type f 2>/dev/null)

if [ -z "$SCAD_FILES" ]; then
  exit 0
fi

if ! command -v openscad &>/dev/null; then
  echo '{"systemMessage": "ClaudeCAD: Skipping model validation — openscad not installed."}'
  exit 0
fi

results=()
all_passed=true

while IFS= read -r scad_file; do
  filename=$(basename "$scad_file")
  if bash "$VALIDATE_SCRIPT" "$scad_file" 2>&1 | grep -q "All checks passed"; then
    results+=("${filename}: PASSED")
  else
    results+=("${filename}: FAILED")
    all_passed=false
  fi
done <<< "$SCAD_FILES"

results_text=$(printf ", %s" "${results[@]}")
results_text="${results_text:2}"

if [ "$all_passed" = true ]; then
  echo "{\"systemMessage\": \"ClaudeCAD validation: All models passed. ${results_text}\"}"
else
  echo "{\"systemMessage\": \"ClaudeCAD validation: Some models failed. ${results_text}\"}"
fi

exit 0
