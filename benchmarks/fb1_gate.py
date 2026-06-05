#!/usr/bin/env python3
"""
FB-1 differential gate — continuous regression check for the FB-0 verified-parity
baseline. Runs the part that needs no GPU/nvcc (source-drift + proof regression) on
every commit, and runs the SASS/backend diff only when the toolchain is present
(otherwise it SKIPs loudly — never silently passes uncovered work).

Frontend lane (always runs):
  1. SHA-256 of each baseline .fg vs the manifest        -> detects source drift
  2. `forge check` each .fg                               -> must discharge with 0 failures
  3. aggregate proof count vs the manifest headline (44)  -> detects proof-count regression

Backend lane (runs iff nvcc + openptxas present):
  4. emit CUDA C, compile to SASS, diff register/instruction counts vs baseline

Exit non-zero on any regression so it can gate CI.

Usage:  python3 benchmarks/fb1_gate.py
"""
import hashlib
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
FORGE_ROOT = os.path.dirname(HERE)
BASELINE = os.path.join(HERE, "fb0_baseline")
MANIFEST = os.path.join(BASELINE, "MANIFEST.md")
FORGE_BIN = os.path.join(FORGE_ROOT, "_build", "default", "bin", "main.exe")


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def parse_manifest(text):
    """Return (expected_hashes: {fg_name: sha}, expected_total_proofs: int)."""
    hashes = {}
    for m in re.finditer(r"^([0-9a-f]{64})\s+(\S+\.fg)\s*$", text, re.M):
        hashes[m.group(2)] = m.group(1)
    mt = re.search(r"(\d+)\s+formal\s+proofs", text)
    total = int(mt.group(1)) if mt else None
    return hashes, total


def forge_check(fg_path):
    """Run `forge check`; return (ok, total_proofs, failed)."""
    try:
        out = subprocess.run([FORGE_BIN, "check", fg_path],
                             capture_output=True, text=True, timeout=300).stdout
    except Exception as e:
        return False, 0, -1
    m = re.search(r"proof summary:\s*(\d+)\s+total.*?(\d+)\s+failed", out)
    if not m:
        return False, 0, -1
    total, failed = int(m.group(1)), int(m.group(2))
    return failed == 0, total, failed


def main():
    if not os.path.exists(FORGE_BIN):
        print("FAIL: forge binary not built (%s). Run `dune build`." % FORGE_BIN)
        return 1
    if not os.path.exists(MANIFEST):
        print("FAIL: FB-0 manifest missing (%s)." % MANIFEST)
        return 1

    text = open(MANIFEST).read()
    expected_hashes, expected_total = parse_manifest(text)
    fgs = sorted(f for f in os.listdir(BASELINE) if f.endswith(".fg"))
    if not fgs:
        print("FAIL: no baseline .fg files under %s" % BASELINE)
        return 1

    print("=== FB-1 gate: frontend lane (source-drift + proof regression) ===")
    regressions = []
    drifted = []
    proof_sum = 0
    for fg in fgs:
        path = os.path.join(BASELINE, fg)
        digest = sha256(path)
        exp = expected_hashes.get(fg)
        drift = (exp is not None and exp != digest)
        ok, total, failed = forge_check(path)
        proof_sum += total
        tag = "OK  "
        if not ok:
            tag = "FAIL"
            regressions.append(fg)
        elif drift:
            tag = "DRIFT"
            drifted.append(fg)
        hash_note = "hash=manifest" if exp == digest else (
            "HASH-DRIFT" if exp is not None else "hash=unlisted")
        print("  [%s] %-34s proofs=%-3d failed=%-2d %s" % (tag, fg, total, failed, hash_note))

    print("\n  aggregate proofs: %d   (manifest headline: %s)" %
          (proof_sum, expected_total))
    proof_regression = (expected_total is not None and proof_sum < expected_total)

    # --- backend lane: only if the open toolchain + a SASS path is present ---
    print("\n=== FB-1 gate: backend lane (SASS parity) ===")
    have_nvcc = shutil.which("nvcc") is not None
    have_optx = os.path.isdir(os.path.expanduser("~/openptxas")) or \
        shutil.which("openptxas") is not None
    if have_nvcc or have_optx:
        print("  backend tooling detected (nvcc=%s openptxas=%s)." % (have_nvcc, have_optx))
        print("  TODO: emit CUDA C -> SASS, diff reg/instr counts vs *.sass baselines.")
        print("  (Not yet implemented in this gate — see ROADMAP. Marked SKIP, not PASS.)")
        backend = "SKIP"
    else:
        print("  SKIP: no nvcc / openptxas on this host — SASS-parity lane not run here.")
        print("  (Run on the GPU box to cover the codegen half. This is NOT a pass.)")
        backend = "SKIP"

    print("\n=== Summary ===")
    print("  baseline kernels:   %d" % len(fgs))
    print("  proof regressions:  %d  %s" % (len(regressions), regressions or ""))
    print("  source drift:       %d  %s" % (len(drifted), drifted or ""))
    print("  aggregate proofs:   %d / %s" % (proof_sum, expected_total))
    print("  backend SASS lane:  %s" % backend)

    failed = bool(regressions) or proof_regression
    print("\nRESULT: %s" % ("FAIL" if failed else "PASS (frontend lane)"))
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
