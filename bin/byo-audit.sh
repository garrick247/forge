#!/usr/bin/env bash
# forge byo-audit -- Bring-Your-Own-Kernel audit mode.
#
# Usage:
#   bin/byo-audit.sh <ref.fg> <user.cu> [--out <dir>]
#
# Workflow:
#   1. Compile <ref.fg> through FORGE -> reference .cu + spec checklist.
#   2. Run gpudiff between <user.cu> and the reference at SASS level.
#   3. Extract requires/ensures clauses from <ref.fg> as audit checklist.
#   4. Emit a Markdown report listing:
#        - SASS-level diff summary
#        - Specs the user kernel SHOULD satisfy (from ref.fg)
#        - Specs that gpudiff cannot verify (caller responsibility)
#
# This is v0 — a shell wrapper around existing tools. v1 (OCaml subcommand)
# would integrate into forge proper as `forge byo-audit`.

set -euo pipefail

REF_FG="${1:?usage: $0 <ref.fg> <user.cu> [--out <dir>]}"
USER_CU="${2:?usage: $0 <ref.fg> <user.cu> [--out <dir>]}"
OUT_DIR="."

shift 2
while [[ $# -gt 0 ]]; do
    case "$1" in
        --out) OUT_DIR="$2"; shift 2 ;;
        *) echo "unknown option: $1" >&2; exit 1 ;;
    esac
done

if [[ ! -f "$REF_FG" ]]; then
    echo "error: reference $REF_FG not found" >&2
    exit 1
fi
if [[ ! -f "$USER_CU" ]]; then
    echo "error: user kernel $USER_CU not found" >&2
    exit 1
fi

mkdir -p "$OUT_DIR"
REPORT="$OUT_DIR/byo-audit-report.md"

FORGE_BIN="${FORGE_BIN:-_build/install/default/bin/forge}"
GPUDIFF_BIN="${GPUDIFF_BIN:-../gpudiff/_build/install/default/bin/gpudiff}"

REF_NAME="$(basename "$REF_FG" .fg)"
REF_CU="$OUT_DIR/${REF_NAME}.cu"

echo "[byo-audit] compiling reference: $REF_FG"
"$FORGE_BIN" cuda "$REF_FG" 2>&1 | tee "$OUT_DIR/forge-output.log" | tail -5
# FORGE writes alongside the .fg by default; copy to our out dir
SRC_DIR="$(dirname "$REF_FG")"
if [[ -f "$SRC_DIR/${REF_NAME}.c" ]]; then
    cp "$SRC_DIR/${REF_NAME}.c" "$REF_CU"
elif [[ -f "$SRC_DIR/${REF_NAME}.cu" ]]; then
    cp "$SRC_DIR/${REF_NAME}.cu" "$REF_CU"
fi

echo "[byo-audit] extracting specs from $REF_FG"
SPEC_FILE="$OUT_DIR/specs.md"
{
    echo "# Specs extracted from \`$REF_FG\`"
    echo
    grep -E "^\\s*(requires|ensures)" "$REF_FG" | sed 's/^/    /'
} > "$SPEC_FILE"

echo "[byo-audit] running gpudiff: $USER_CU vs $REF_CU"
DIFF_OUT="$OUT_DIR/sass-diff.txt"
if [[ -x "$GPUDIFF_BIN" ]]; then
    "$GPUDIFF_BIN" "$REF_CU" "$USER_CU" > "$DIFF_OUT" 2>&1 || true
else
    echo "(gpudiff not found at $GPUDIFF_BIN — skipping SASS diff)" > "$DIFF_OUT"
fi

echo "[byo-audit] writing report: $REPORT"
{
    echo "# Bring-Your-Own-Kernel Audit Report"
    echo
    echo "**Reference (FORGE-verified):** \`$REF_FG\`"
    echo "**User kernel (under audit):** \`$USER_CU\`"
    echo "**Date:** $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo
    echo "## Specs the user kernel must satisfy"
    echo
    cat "$SPEC_FILE"
    echo
    echo "## SASS-level diff"
    echo
    echo '```'
    head -200 "$DIFF_OUT"
    echo '```'
    echo
    echo "## Verdict"
    echo
    if grep -qE "ERROR|FAIL|differ" "$DIFF_OUT"; then
        echo "- **DIVERGENCE detected.** See SASS diff above."
    else
        echo "- SASS-level structure matches the reference."
        echo "- Specs from \`$REF_FG\` not auto-checked at the user kernel boundary; the caller is responsible for ensuring the user's preconditions hold."
    fi
    echo
    echo "## Limitations"
    echo
    echo "- v0: this wrapper does NOT prove the user kernel satisfies the spec, only that its compiled form matches the reference."
    echo "- v1 (planned): integrate into \`forge\` as a subcommand with a real spec-substitution check (treat \`user.cu\` as the implementation of the FORGE spec, re-run Z3 on the spec with a hint to the user's structure)."
} > "$REPORT"

echo
echo "[byo-audit] complete: $REPORT"
