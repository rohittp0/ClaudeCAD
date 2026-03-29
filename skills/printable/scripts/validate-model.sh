#!/bin/bash
# validate-model.sh — Render OpenSCAD model, export binary STL, validate mesh
# Usage: validate-model.sh <input.scad> [output.stl] [--copy-to DIR]

set -e

INPUT="$1"
OUTPUT="${2:-${INPUT%.scad}.stl}"
COPY_DIR=""

# Parse --copy-to flag
for arg in "$@"; do
    case "$arg" in
        --copy-to)
            shift_next=1
            ;;
        *)
            if [ "$shift_next" = "1" ]; then
                COPY_DIR="$arg"
                shift_next=0
            fi
            ;;
    esac
done

if [ -z "$INPUT" ] || [ ! -f "$INPUT" ]; then
    echo "Usage: validate-model.sh <input.scad> [output.stl] [--copy-to DIR]"
    echo "  Renders an OpenSCAD file to binary STL and validates the mesh."
    exit 1
fi

echo "=== OpenSCAD Model Validator ==="
echo "Input:  $INPUT"
echo "Output: $OUTPUT"
echo ""

# --- Step 1: Render with OpenSCAD ---
echo "--- Rendering with OpenSCAD ---"
RENDER_OUTPUT=$(openscad -o "$OUTPUT" --export-format binstl "$INPUT" 2>&1)
RENDER_EXIT=$?

# Check for warnings
WARNINGS=$(echo "$RENDER_OUTPUT" | grep -i "WARNING" || true)
ERRORS=$(echo "$RENDER_OUTPUT" | grep -i "ERROR" || true)

# Extract stats
SIMPLE=$(echo "$RENDER_OUTPUT" | grep "Simple:" | awk '{print $2}')
VOLUMES=$(echo "$RENDER_OUTPUT" | grep "Volumes:" | awk '{print $2}')
VERTICES=$(echo "$RENDER_OUTPUT" | grep "Vertices:" | awk '{print $2}')
RENDER_TIME=$(echo "$RENDER_OUTPUT" | grep "Total rendering time:" | awk '{print $NF}')

echo "  Render time: ${RENDER_TIME:-unknown}"
echo "  Vertices: ${VERTICES:-unknown}"
echo "  Simple (manifold): ${SIMPLE:-unknown}"
echo "  Volumes: ${VOLUMES:-unknown}"

if [ $RENDER_EXIT -ne 0 ]; then
    echo "  ❌ RENDER FAILED (exit code $RENDER_EXIT)"
    echo "$RENDER_OUTPUT"
    exit 1
fi

if [ -n "$WARNINGS" ]; then
    echo "  ⚠️  WARNINGS:"
    echo "$WARNINGS" | sed 's/^/    /'
fi

if [ -n "$ERRORS" ]; then
    echo "  ❌ ERRORS:"
    echo "$ERRORS" | sed 's/^/    /'
    exit 1
fi

if [ "$SIMPLE" != "yes" ]; then
    echo "  ❌ FAIL: Geometry is not manifold (Simple != yes)"
    exit 1
fi

if [ "$VOLUMES" != "2" ]; then
    echo "  ⚠️  Unexpected volume count: $VOLUMES (expected 2: solid + void)"
fi

echo "  ✅ OpenSCAD render OK"
echo ""

# --- Step 2: Validate with admesh ---
if command -v admesh &>/dev/null; then
    echo "--- Validating mesh with admesh ---"
    ADMESH_OUTPUT=$(admesh "$OUTPUT" 2>&1)

    # "Number of parts       :     1        Volume   :  28300.75"
    PARTS=$(echo "$ADMESH_OUTPUT" | grep "Number of parts" | sed 's/.*Number of parts[^:]*:\s*//' | awk '{print $1}')
    VOLUME=$(echo "$ADMESH_OUTPUT" | grep "Volume" | sed 's/.*Volume[^:]*:\s*//' | awk '{print $1}')
    # "Total disconnected facets        :     0                   0"
    DISCONNECTED=$(echo "$ADMESH_OUTPUT" | grep "Total disconnected" | awk -F: '{print $2}' | awk '{print $NF}')
    DEGENERATE=$(echo "$ADMESH_OUTPUT" | grep "Degenerate facets" | awk -F: '{print $2}' | awk '{print $NF}')
    FACETS=$(echo "$ADMESH_OUTPUT" | grep "Number of facets" | head -1 | awk -F: '{print $2}' | awk '{print $NF}')

    echo "  Parts: $PARTS"
    echo "  Facets: $FACETS"
    echo "  Disconnected: $DISCONNECTED"
    echo "  Degenerate: $DEGENERATE"
    echo "  Volume: ${VOLUME}mm³"

    PASS=true

    if [ "$PARTS" != "1" ]; then
        echo "  ❌ FAIL: Multiple parts detected ($PARTS) — model has disconnected components"
        PASS=false
    fi

    if [ "$DISCONNECTED" != "0" ]; then
        echo "  ❌ FAIL: Disconnected facets ($DISCONNECTED) — mesh has holes"
        PASS=false
    fi

    if [ "$DEGENERATE" != "0" ]; then
        echo "  ⚠️  Degenerate facets ($DEGENERATE) — may cause slicer issues"
    fi

    if [ "$PASS" = true ]; then
        echo "  ✅ Mesh validation PASSED"
    else
        exit 1
    fi
else
    echo "--- admesh not found, skipping mesh validation ---"
    echo "  Install: brew install admesh (macOS) or apt install admesh (Linux)"
fi

echo ""

# --- Step 3: Copy to destination ---
if [ -n "$COPY_DIR" ]; then
    cp "$OUTPUT" "$COPY_DIR/"
    echo "Copied to $COPY_DIR/$(basename "$OUTPUT")"
fi

echo "=== All checks passed ✅ ==="
echo "STL: $OUTPUT"
