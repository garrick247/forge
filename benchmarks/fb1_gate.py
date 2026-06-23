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

Backend lane (runs iff nvcc present):
  For each baseline kernel:
    a. `forge build` the .fg fresh -> CUDA C (.cu), strip the main() stub
    b. nvcc -arch=sm_120 -cubin   -> cubin -> nvdisasm/cuobjdump
    c. register count  (cuobjdump -res-usage, "REG:N")
       instruction cnt (nvdisasm -raw, non-blank/non-comment/non-directive lines)
       — same methodology as benchmarks/forgebench.py that produced the baseline.
    d. PARITY CHECKS (hard fail):
       - registers   == MANIFEST  (register count is stable across nvcc versions)
       - instructions == BASELINE-NOW, i.e. the committed *_clean.cu recompiled
         with the *present* nvcc. The MANIFEST instruction counts were recorded
         under nvcc 13.2; 13.3+ shifts them by a handful in both directions even
         for byte-identical source, so comparing fresh-forge output against a
         same-toolchain recompile of the frozen baseline isolates a genuine
         FORGE codegen regression from a mere nvcc-version delta. The fresh-vs-
         MANIFEST instruction delta is printed as informational drift.

  Not yet covered (documented, not silently skipped): an open-stack differential
  (openptxas vs ptxas on the emitted .ptx). openptxas's current coverage is the
  ZK-kernel set, not these fp16/GEMM/attention kernels, so wiring it here would
  add expected-failure noise rather than signal. Track under the openptxas threads.

Exit non-zero on any regression so it can gate CI.

Usage:  python3 benchmarks/fb1_gate.py
"""
import hashlib
import os
import re
import shutil
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
FORGE_ROOT = os.path.dirname(HERE)
BASELINE = os.path.join(HERE, "fb0_baseline")
MANIFEST = os.path.join(BASELINE, "MANIFEST.md")
FORGE_BIN = os.path.join(FORGE_ROOT, "_build", "default", "bin", "main.exe")
STD_DIR = os.path.join(FORGE_ROOT, "demos", "std")

NVCC = "nvcc"
NVDISASM = "nvdisasm"
CUOBJDUMP = "cuobjdump"
SM_ARCH = "sm_120"

# Make the gate robust to a login shell that didn't export the CUDA bindir.
_CUDA_BIN = "/usr/local/cuda/bin"
if os.path.isdir(_CUDA_BIN) and _CUDA_BIN not in os.environ.get("PATH", ""):
    os.environ["PATH"] = _CUDA_BIN + os.pathsep + os.environ.get("PATH", "")

# Frozen FB-0 kernels: (baseline .fg filename, MANIFEST table name).
KERNEL_MAP = [
    ("1046_multi_reduction.fg", "reduce_sum"),
    ("1047_fp16_gemm.fg",       "fp16_gemm"),
    ("1048_conv2d.fg",          "conv2d"),
    ("1049_flash_attention.fg", "flash_attention"),
    ("1050_tiled_smem_gemm.fg", "tiled_smem_gemm"),
]


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


def parse_manifest_metrics(text):
    """Return {kernel_name: (registers, instructions)} from the kernel table.

    Table rows look like:  | reduce_sum | 18 | 169 | 436 | 3 | 0 |
    The **Total** row has empty reg/instr cells and is skipped by \\w+.
    """
    out = {}
    for m in re.finditer(r"^\|\s*(\w+)\s*\|\s*(\d+)\s*\|\s*(\d+)\s*\|", text, re.M):
        out[m.group(1)] = (int(m.group(2)), int(m.group(3)))
    return out


def forge_check(fg_path):
    """Run `forge check`; return (ok, total_proofs, failed)."""
    try:
        out = subprocess.run([FORGE_BIN, "check", fg_path],
                             capture_output=True, text=True, timeout=300).stdout
    except Exception:
        return False, 0, -1
    m = re.search(r"proof summary:\s*(\d+)\s+total.*?(\d+)\s+failed", out)
    if not m:
        return False, 0, -1
    total, failed = int(m.group(1)), int(m.group(2))
    return failed == 0, total, failed


# ── backend-lane helpers ───────────────────────────────────────────

_MAIN_DECL = re.compile(r"^int\s+(?:__attribute__\(\(weak\)\)\s+)?main\s*\(\)\s*;\s*$", re.M)
_MAIN_DEF = re.compile(r"^int\s+(?:__attribute__\(\(weak\)\)\s+)?main\s*\(\)\s*\{.*?^\}\s*$", re.M | re.S)


def strip_main(src):
    """Drop the emitted main() stub (decl + def, plain or weak) so nvcc -cubin
    accepts the device-only translation unit. Mirrors forgebench.nvcc_compile."""
    return _MAIN_DEF.sub("", _MAIN_DECL.sub("", src))


def _run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True)


def measure_cu(cu_path, workdir, tag):
    """strip main -> nvcc cubin -> (reg, instr, errlog). reg/instr None on nvcc failure."""
    clean = strip_main(open(cu_path).read())
    clean_path = os.path.join(workdir, tag + "_clean.cu")
    with open(clean_path, "w") as f:
        f.write(clean)
    cubin = os.path.join(workdir, tag + ".cubin")
    r = _run([NVCC, "-arch=" + SM_ARCH, "-cubin", "-o", cubin, clean_path])
    if r.returncode != 0 or not os.path.exists(cubin):
        return None, None, (r.stdout + r.stderr).strip()
    dis = _run([NVDISASM, "-raw", cubin]).stdout
    instr = len([l for l in dis.split("\n")
                 if l.strip() and not l.strip().startswith("//")
                 and not l.strip().startswith(".")])
    res = _run([CUOBJDUMP, "-res-usage", cubin]).stdout
    m = re.search(r"REG:(\d+)", res)
    reg = int(m.group(1)) if m else None
    return reg, instr, None


def forge_build_fresh(fg_src, workdir, tag):
    """Copy the baseline .fg into workdir (with a std symlink so `use std::*`
    resolves), run `forge build`, return (fresh_cu_path, errlog)."""
    fg_dst = os.path.join(workdir, tag + ".fg")
    shutil.copyfile(fg_src, fg_dst)
    std_link = os.path.join(workdir, "std")
    if not os.path.exists(std_link):
        try:
            os.symlink(STD_DIR, std_link)
        except OSError:
            pass
    r = _run([FORGE_BIN, "build", fg_dst])
    out = r.stdout + r.stderr
    cu = os.path.join(workdir, tag + ".cu")
    if "all obligations discharged" in out and os.path.exists(cu):
        return cu, None
    return None, out.strip()


def backend_lane(manifest_metrics):
    """Returns (status: 'PASS'|'FAIL'|'SKIP', failures: list[str])."""
    print("\n=== FB-1 gate: backend lane (SASS parity) ===")
    if shutil.which(NVCC) is None:
        print("  SKIP: no nvcc on this host — SASS-parity lane not run here.")
        print("  (Run on the GPU box to cover the codegen half. This is NOT a pass.)")
        return "SKIP", []
    print("  nvcc=%s  nvdisasm=%s  cuobjdump=%s" %
          (shutil.which(NVCC), shutil.which(NVDISASM), shutil.which(CUOBJDUMP)))

    failures = []
    workdir = tempfile.mkdtemp(prefix="fb1_backend_")
    try:
        for fg, name in KERNEL_MAP:
            fg_path = os.path.join(BASELINE, fg)
            base_clean = os.path.join(BASELINE, fg.replace(".fg", "_clean.cu"))
            man = manifest_metrics.get(name)  # (reg, instr) recorded under nvcc 13.2

            # baseline-now: recompile the FROZEN committed _clean.cu with present nvcc
            bn_reg = bn_instr = None
            if os.path.exists(base_clean):
                bn_reg, bn_instr, bn_err = measure_cu(base_clean, workdir, name + "_base")
                if bn_reg is None:
                    print("  [WARN] %-16s baseline _clean.cu won't compile here: %s"
                          % (name, (bn_err or "")[:90]))

            # fresh: build the .fg with the CURRENT forge, then compile the same way
            fresh_cu, ferr = forge_build_fresh(fg_path, workdir, name + "_fresh")
            if fresh_cu is None:
                print("  [FAIL] %-16s forge build failed: %s" % (name, (ferr or "")[:110]))
                failures.append(name)
                continue
            fr_reg, fr_instr, cerr = measure_cu(fresh_cu, workdir, name + "_fresh")
            if fr_reg is None:
                print("  [FAIL] %-16s fresh forge .cu won't compile: %s" % (name, (cerr or "")[:110]))
                failures.append(name)
                continue

            # parity checks: reg vs MANIFEST (stable), instr vs baseline-now (toolchain-robust)
            reg_ok = (man is None) or (fr_reg == man[0])
            instr_ok = (bn_instr is None) or (fr_instr == bn_instr)
            status = "OK  " if (reg_ok and instr_ok) else "FAIL"
            if status == "FAIL":
                failures.append(name)
            man_reg = man[0] if man else "?"
            man_instr = man[1] if man else "?"
            drift = "" if (man and fr_instr == man[1]) else \
                "  [instr drift vs manifest %s: nvcc-version]" % man_instr
            print("  [%s] %-16s reg=%-3d (manifest %s)  instr=%-4d (baseline-now %s, manifest %s)%s"
                  % (status, name, fr_reg, man_reg, fr_instr,
                     bn_instr if bn_instr is not None else "?", man_instr, drift))
    finally:
        shutil.rmtree(workdir, ignore_errors=True)

    return ("FAIL" if failures else "PASS"), failures


def main():
    if not os.path.exists(FORGE_BIN):
        print("FAIL: forge binary not built (%s). Run `dune build`." % FORGE_BIN)
        return 1
    if not os.path.exists(MANIFEST):
        print("FAIL: FB-0 manifest missing (%s)." % MANIFEST)
        return 1

    text = open(MANIFEST).read()
    expected_hashes, expected_total = parse_manifest(text)
    manifest_metrics = parse_manifest_metrics(text)
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

    # --- backend lane ---
    backend, backend_failures = backend_lane(manifest_metrics)

    print("\n=== Summary ===")
    print("  baseline kernels:   %d" % len(fgs))
    print("  proof regressions:  %d  %s" % (len(regressions), regressions or ""))
    print("  source drift:       %d  %s" % (len(drifted), drifted or ""))
    print("  aggregate proofs:   %d / %s" % (proof_sum, expected_total))
    print("  backend SASS lane:  %s  %s" % (backend, backend_failures or ""))

    failed = bool(regressions) or proof_regression or (backend == "FAIL")
    if backend == "SKIP":
        result = "PASS (frontend lane only — backend SKIPped, not covered here)"
    elif failed:
        result = "FAIL"
    else:
        result = "PASS (frontend + backend lanes)"
    print("\nRESULT: %s" % result)
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
