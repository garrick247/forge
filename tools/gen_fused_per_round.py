#!/usr/bin/env python3
"""Emit demos/2010_bench_baby_bear_fused_perm_per_round.fg.

22 per-round `#[device]` functions that mutate a 16-felt span in-place.
The forall invariant `forall k in [base, base+16), s[k] < BB_P` is
maintained as both pre and post-condition on every round function, so
the kernel's SMT context stays bounded — at any point during the kernel,
Z3 only carries one universal fact about the working span plus the
inputs.

Same byte-identical Plonky3 BB-16 perm.
"""
from __future__ import annotations

P = 2013265921

EXT_INIT = [
    [0x69cbb6af, 0x46ad93f9, 0x60a00f4e, 0x6b1297cd, 0x23189afe, 0x732e7bef,
     0x72c246de, 0x2c941900, 0x0557eede, 0x1580496f, 0x3a3ea77b, 0x54f3f271,
     0x0f49b029, 0x47872fe1, 0x221e2e36, 0x1ab7202e],
    [0x487779a6, 0x3851c9d8, 0x38dc17c0, 0x209f8849, 0x268dcee8, 0x350c48da,
     0x5b9ad32e, 0x0523272b, 0x3f89055b, 0x01e894b2, 0x13ddedde, 0x1b2ef334,
     0x7507d8b4, 0x6ceeb94e, 0x52eb6ba2, 0x50642905],
    [0x05453f3f, 0x06349efc, 0x6922787c, 0x04bfff9c, 0x768c714a, 0x3e9ff21a,
     0x15737c9c, 0x2229c807, 0x0d47f88c, 0x097e0ecc, 0x27eadba0, 0x2d7d29e4,
     0x3502aaa0, 0x0f475fd7, 0x29fbda49, 0x018afffd],
    [0x0315b618, 0x6d4497d1, 0x1b171d9e, 0x52861abd, 0x2e5d0501, 0x3ec8646c,
     0x6e5f250a, 0x148ae8e6, 0x17f5fa4a, 0x3e66d284, 0x0051aa3b, 0x483f7913,
     0x2cfe5f15, 0x023427ca, 0x2cc78315, 0x1e36ea47],
]
EXT_FINAL = [
    [0x7290a80d, 0x6f7e5329, 0x598ec8a8, 0x76a859a0, 0x6559e868, 0x657b83af,
     0x13271d3f, 0x1f876063, 0x0aeeae37, 0x706e9ca6, 0x46400cee, 0x72a05c26,
     0x2c589c9e, 0x20bd37a7, 0x6a2d3d10, 0x20523767],
    [0x5b8fe9c4, 0x2aa501d6, 0x1e01ac3e, 0x1448bc54, 0x5ce5ad1c, 0x4918a14d,
     0x2c46a83f, 0x4fcf6876, 0x61d8d5c8, 0x6ddf4ff9, 0x11fda4d3, 0x02933a8f,
     0x170eaf81, 0x5a9c314f, 0x49a12590, 0x35ec52a1],
    [0x58eb1611, 0x5e481e65, 0x367125c9, 0x0eba33ba, 0x1fc28ded, 0x066399ad,
     0x0cbec0ea, 0x75fd1af0, 0x50f5bf4e, 0x643d5f41, 0x6f4fe718, 0x5b3cbbde,
     0x1e3afb3e, 0x296fb027, 0x45e1547b, 0x4a8db2ab],
    [0x59986d19, 0x30bcdfa3, 0x1db63932, 0x1d7c2824, 0x53b33681, 0x0673b747,
     0x038a98a3, 0x2c5bce60, 0x351979cd, 0x5008fb73, 0x547bca78, 0x711af481,
     0x3f93bf64, 0x644d987b, 0x3c8bcd87, 0x608758b8],
]
INTERNAL_RC = [
    0x5a8053c0, 0x693be639, 0x3858867d, 0x19334f6b, 0x128f0fd8, 0x4e2b1ccb,
    0x61210ce0, 0x3c318939, 0x0b5b2f22, 0x2edb11d5, 0x213effdf, 0x0cac4606,
    0x241af16d,
]

def inv(x): return pow(x, P - 2, P)
def neg(x): return (P - x) % P
V_DIAG = [
    neg(2), 1, 2, inv(2), 3, 4, neg(inv(2)), neg(3), neg(4),
    inv(256), inv(4), inv(8), inv(1 << 27),
    neg(inv(256)), neg(inv(16)), neg(inv(1 << 27)),
]

# ---- Helper: shape of a single round function -----------------------------

# Each round function takes (s: span<u32>, base: u64). Pre/post: bounds + len.
# Internally:
#   1. Read 16 felts via assert-instantiated forall-get.
#   2. Compute the round's transformation in lets.
#   3. Write 16 felts back to s[base..base+16].
# After the writes Z3 must verify the universal post-bound from the 16
# specific facts. Each write has form `s[base+i] = new_i` where new_i has
# postcondition `< BB_P`. The forall ensures is then provable by
# instantiation across the 16 specific writes.

def emit_pre_post():
    """Pre/post conditions every round function shares.

    Pointwise instead of universal: 16 individual `s[base + i] < BB_P`
    facts work where the forall did not. Z3 quantifier instantiation
    isn't strong enough to generalize 16 specific writes back to a forall,
    but it can match per-index pre/post pairs trivially.
    """
    pre = ["    requires base + 16u64 <= s.len"]
    for i in range(16):
        pre.append(f"    requires s[base + {i}u64] < BABY_BEAR_P")
    post = []
    for i in range(16):
        post.append(f"    ensures s[base + {i}u64] < BABY_BEAR_P")
    return pre + post


def emit_reads(prefix):
    """Read s[base..base+16] into 16 named locals.

    Each read uses the corresponding per-index `s[base + i] < BB_P`
    precondition directly. We still emit a per-read assert as a hint —
    it costs Z3 nothing extra and makes the bound flow into the let
    explicit if FORGE's let-binding doesn't auto-propagate the fact.
    """
    lines = []
    names = []
    for i in range(16):
        v = f"{prefix}_in_{i:02d}"
        lines.append(f"    assert(s[base + {i}u64] < BABY_BEAR_P) \"from per-index requires\";")
        lines.append(f"    let {v}: u32 = s[base + {i}u64];")
        names.append(v)
    return lines, names


def emit_writes(prefix, src_names):
    """Write 16 named locals back to s[base..base+16]."""
    lines = []
    for i in range(16):
        lines.append(f"    s[base + {i}u64] = {src_names[i]};")
    return lines


def emit_chunk_mds(prefix, in_names):
    """Apply M_4 to each chunk of 4 inputs, returning per-chunk 4-felt rows.

    Returns (lines, cy[k][j]) where cy[k][j] = M_4_row_j applied to chunk k.
    """
    lines = []
    cy = [[None] * 4 for _ in range(4)]
    for k in range(4):
        a, b, c, d = in_names[k * 4: k * 4 + 4]
        for j in range(4):
            v = f"{prefix}_c{k}_y{j}"
            lines.append(f"    let {v}: u32 = baby_bear_p2_ext_chunk_y{j}({a}, {b}, {c}, {d});")
            cy[k][j] = v
    return lines, cy


def emit_col_sums(prefix, cy):
    """Compute cs[j] = sum_k cy[k][j] for j in 0..3."""
    lines = []
    cs = [None] * 4
    for j in range(4):
        a01 = f"{prefix}_csa_{j}"
        a23 = f"{prefix}_csb_{j}"
        cv = f"{prefix}_cs_{j}"
        lines.append(f"    let {a01}: u32 = baby_bear_add({cy[0][j]}, {cy[1][j]});")
        lines.append(f"    let {a23}: u32 = baby_bear_add({cy[2][j]}, {cy[3][j]});")
        lines.append(f"    let {cv}: u32 = baby_bear_add({a01}, {a23});")
        cs[j] = cv
    return lines, cs


def emit_M_E_apply(prefix, in_names):
    """Apply full M_E to in_names; return 16 output names."""
    lines = []
    chunk_lines, cy = emit_chunk_mds(prefix, in_names)
    lines.extend(chunk_lines)
    cs_lines, cs = emit_col_sums(prefix, cy)
    lines.extend(cs_lines)
    out_names = []
    for k in range(4):
        for j in range(4):
            v = f"{prefix}_out_{k*4 + j:02d}"
            lines.append(f"    let {v}: u32 = baby_bear_add({cy[k][j]}, {cs[j]});")
            out_names.append(v)
    return lines, out_names


def emit_init_ME() -> str:
    lines = []
    lines.append("#[device]")
    lines.append("fn apply_init_ME(s: span<u32>, base: u64)")
    lines.extend(emit_pre_post())
    lines.append("{")
    rl, rn = emit_reads("ime")
    lines.extend(rl)
    ml, mn = emit_M_E_apply("ime_m", rn)
    lines.extend(ml)
    lines.extend(emit_writes("ime", mn))
    lines.append("}")
    return "\n".join(lines)


def emit_ext_round(name: str, rc_prefix: str) -> str:
    """rc_prefix: e.g. 'RC_INIT_0' or 'RC_FINAL_3'."""
    lines = []
    lines.append("#[device]")
    lines.append(f"fn {name}(s: span<u32>, base: u64)")
    lines.extend(emit_pre_post())
    lines.append("{")
    rl, rn = emit_reads(name)
    lines.extend(rl)
    # ARK + SBOX (uses baby_bear_p2_ext_sbox_with_rc).
    sb = []
    for i in range(16):
        v = f"{name}_sb_{i:02d}"
        rc = f"{rc_prefix}_{i:02d}"
        lines.append(f"    let {v}: u32 = baby_bear_p2_ext_sbox_with_rc({rn[i]}, {rc});")
        sb.append(v)
    # M_E
    ml, mn = emit_M_E_apply(f"{name}_m", sb)
    lines.extend(ml)
    lines.extend(emit_writes(name, mn))
    lines.append("}")
    return "\n".join(lines)


def emit_partial_round(name: str, rc_const: str) -> str:
    lines = []
    lines.append("#[device]")
    lines.append(f"fn {name}(s: span<u32>, base: u64)")
    lines.extend(emit_pre_post())
    lines.append("{")
    rl, rn = emit_reads(name)
    lines.extend(rl)
    # SBOX of state[0] + rc.
    sb0 = f"{name}_sb0"
    lines.append(f"    let {sb0}: u32 = baby_bear_p2_int_sbox_with_rc({rn[0]}, {rc_const});")
    # sum = sb0 + s1 + s2 + ... + s15.
    s_vars = [sb0] + rn[1:]
    cur = s_vars[0]
    for i in range(1, 16):
        new = f"{name}_sumacc_{i:02d}"
        lines.append(f"    let {new}: u32 = baby_bear_add({cur}, {s_vars[i]});")
        cur = new
    sum_var = cur
    # Compute 16 outputs.
    out_names = [None] * 16
    # i=0: sum - 2*sb0
    lines.append(f"    let {name}_d2_sb0: u32 = baby_bear_double({sb0});")
    lines.append(f"    let {name}_o_00: u32 = baby_bear_sub({sum_var}, {name}_d2_sb0);")
    out_names[0] = f"{name}_o_00"
    # i=1: s1 + sum (V[1] = 1)
    lines.append(f"    let {name}_o_01: u32 = baby_bear_add({rn[1]}, {sum_var});")
    out_names[1] = f"{name}_o_01"
    # i=2..15: V[i] * s_i + sum
    for i in range(2, 16):
        v_const = f"V_{i:02d}"
        si = rn[i]
        v_name = f"{name}_vmul_{i:02d}"
        lines.append(f"    let {v_name}: u32 = baby_bear_mul({si}, {v_const});")
        out = f"{name}_o_{i:02d}"
        lines.append(f"    let {out}: u32 = baby_bear_add({v_name}, {sum_var});")
        out_names[i] = out
    lines.extend(emit_writes(name, out_names))
    lines.append("}")
    return "\n".join(lines)


def emit_copy_state() -> str:
    """Copy state[base..base+16] into out[base..base+16].

    Pre: state has the universal forall (kernel-level invariant).
    Post: out has 16 pointwise facts (round-function invariant).
    The 16 asserts up front instantiate the forall to specific indices.
    """
    lines = []
    lines.append("#[device]")
    lines.append("fn copy_state_window(out: span<u32>, state: span<u32>, base: u64)")
    lines.append("    requires base + 16u64 <= out.len")
    lines.append("    requires base + 16u64 <= state.len")
    lines.append("    requires forall k: u64, k < state.len ==> state[k] < BABY_BEAR_P")
    for i in range(16):
        lines.append(f"    ensures out[base + {i}u64] < BABY_BEAR_P")
    lines.append("{")
    for i in range(16):
        lines.append(f"    assert(state[base + {i}u64] < BABY_BEAR_P) \"forall instantiated\";")
    for i in range(16):
        lines.append(f"    out[base + {i}u64] = state[base + {i}u64];")
    lines.append("}")
    return "\n".join(lines)


def kernel_body() -> list[str]:
    lines = []
    lines.append("#[kernel]")
    lines.append("fn baby_bear_fused_perm_pr_kernel(")
    lines.append("    out:   span<u32>,")
    lines.append("    state: span<u32>,")
    lines.append("    n:     u64)")
    lines.append("    requires n > 0")
    lines.append("    requires 16 * n <= out.len")
    lines.append("    requires 16 * n <= state.len")
    lines.append("    requires forall k: u64, k < state.len ==> state[k] < BABY_BEAR_P")
    lines.append("{")
    lines.append("    let tid: u64 = blockIdx_x * blockDim_x + threadIdx_x;")
    lines.append("    if tid < n {")
    lines.append("        let base: u64 = 16u64 * tid;")
    lines.append("        copy_state_window(out, state, base);")
    lines.append("        apply_init_ME(out, base);")
    for r in range(4):
        lines.append(f"        apply_ext_round_init_{r}(out, base);")
    for r in range(13):
        lines.append(f"        apply_partial_round_{r:02d}(out, base);")
    for r in range(4):
        lines.append(f"        apply_ext_round_final_{r}(out, base);")
    lines.append("    }")
    lines.append("}")
    return lines


def emit_consts() -> list[str]:
    lines = []
    for r, row in enumerate(EXT_INIT):
        for i, v in enumerate(row):
            lines.append(f"const RC_INIT_{r}_{i:02d}: u32 = {v}u32;")
    for r, row in enumerate(EXT_FINAL):
        for i, v in enumerate(row):
            lines.append(f"const RC_FINAL_{r}_{i:02d}: u32 = {v}u32;")
    for i, v in enumerate(INTERNAL_RC):
        lines.append(f"const RC_INT_{i:02d}: u32 = {v}u32;")
    for i, v in enumerate(V_DIAG):
        lines.append(f"const V_{i:02d}: u32 = {v}u32;")
    return lines


def main():
    out = []
    out.append("// Fused BabyBear-16 Poseidon2 perm — per-ROUND factored,")
    out.append("// in-place span mutation. The round functions all share the")
    out.append("// invariant `forall k in [base, base+16), s[k] < BB_P` as both")
    out.append("// pre and post-condition, so the kernel's accumulating SMT")
    out.append("// state stays bounded between rounds.")
    out.append("//")
    out.append("// Same byte-identical Plonky3 BB-16 perm.")
    out.append("// Generated by tools/gen_fused_per_round.py.")
    out.append("")
    out.append("use std::gpu;")
    out.append("use std::baby_bear;")
    out.append("use std::poseidon2_baby_bear;")
    out.append("")
    out.extend(emit_consts())
    out.append("")
    out.append(emit_copy_state())
    out.append("")
    out.append(emit_init_ME())
    out.append("")
    for r in range(4):
        out.append(emit_ext_round(f"apply_ext_round_init_{r}", f"RC_INIT_{r}"))
        out.append("")
    for r in range(13):
        out.append(emit_partial_round(f"apply_partial_round_{r:02d}", f"RC_INT_{r:02d}"))
        out.append("")
    for r in range(4):
        out.append(emit_ext_round(f"apply_ext_round_final_{r}", f"RC_FINAL_{r}"))
        out.append("")
    out.extend(kernel_body())
    out.append("")
    out.append("fn main() -> u64 { 0u64 }")
    print("\n".join(out))


if __name__ == "__main__":
    main()
