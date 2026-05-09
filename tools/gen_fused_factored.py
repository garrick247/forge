#!/usr/bin/env python3
"""Emit demos/2009_bench_baby_bear_fused_perm_factored.fg.

Same byte-identical Plonky3 BB-16 Poseidon2 perm as 2008_*, but factored
into per-output-element `#[device]` helpers. Each helper has bounded SMT
(16 inputs, ~30 ops, ~30 obligations), so FORGE/Z3 can verify the whole
permutation without the quadratic state blow-up the monolithic 2008_*
form hit.

Layout:
- 48 helpers: init_ME_out_<i>, ext_round_out_<i>, partial_round_out_<i>
- Kernel: chain of helper calls per round
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

# -------- Helper-body emission ---------------------------------------------

# We use existing FORGE-verified primitives from std/baby_bear and
# std/poseidon2_baby_bear:
#   baby_bear_add, baby_bear_sub, baby_bear_mul, baby_bear_double, baby_bear_neg
#   baby_bear_p2_ext_chunk_y0/y1/y2/y3 (M_4 rows on 4 felts)
#
# These all have postcondition `result < BABY_BEAR_P`, so chains of them
# preserve the bound through Z3.

def emit_M_E_chunk_lines(prefix, in_args):
    """Emit lines computing the 16 chunk-MDS values for a 16-felt input.

    Returns lines and a list `cy[k][j]` of variable names where k=0..3
    is chunk index and j=0..3 is row (output position within chunk).
    """
    lines = []
    cy = [[None] * 4 for _ in range(4)]  # type: ignore
    for k in range(4):
        a, b, c, d = in_args[k * 4: k * 4 + 4]
        for j in range(4):
            v = f"{prefix}_c{k}_y{j}"
            lines.append(
                f"    let {v}: u32 = baby_bear_p2_ext_chunk_y{j}({a}, {b}, {c}, {d});"
            )
            cy[k][j] = v
    return lines, cy


def emit_col_sum_lines(prefix, cy):
    """Emit lines computing column sums cs[j] = cy[0][j]+cy[1][j]+cy[2][j]+cy[3][j]."""
    lines = []
    cs = [None] * 4  # type: ignore
    for j in range(4):
        a01 = f"{prefix}_csa_{j}"
        a23 = f"{prefix}_csb_{j}"
        cv = f"{prefix}_cs_{j}"
        lines.append(f"    let {a01}: u32 = baby_bear_add({cy[0][j]}, {cy[1][j]});")
        lines.append(f"    let {a23}: u32 = baby_bear_add({cy[2][j]}, {cy[3][j]});")
        lines.append(f"    let {cv}: u32 = baby_bear_add({a01}, {a23});")
        cs[j] = cv
    return lines, cs


def emit_M_E_helper(name, in_args):
    """Emit a `#[device]` helper that returns one of 16 outputs of M_E
    applied to in_args. The helper is parameterized by which output (k, j)
    it produces; we generate 16 of them (one per (k, j) pair).
    """
    helpers = []
    for k in range(4):
        for j in range(4):
            i = k * 4 + j
            fn_name = f"{name}_{i:02d}"
            params = ", ".join(f"x{p:02d}: u32" for p in range(16))
            requires = "\n    ".join(
                f"requires x{p:02d} < BABY_BEAR_P" for p in range(16)
            )
            lines = []
            lines.append("#[device]")
            lines.append(f"fn {fn_name}({params}) -> u32")
            lines.append(f"    {requires}")
            lines.append("    ensures result < BABY_BEAR_P")
            lines.append("{")
            mlines, cy = emit_M_E_chunk_lines(
                "h", [f"x{p:02d}" for p in range(16)]
            )
            lines.extend(mlines)
            cslines, cs = emit_col_sum_lines("h", cy)
            lines.extend(cslines)
            lines.append(f"    baby_bear_add({cy[k][j]}, {cs[j]})")
            lines.append("}")
            helpers.append("\n".join(lines))
    return "\n\n".join(helpers)


def emit_partial_helper():
    """Emit `partial_round_out_<i>(sb0, s1..s15)` for i in 0..15.

    sb0 = SBOX(s0 + rc) — already computed by caller.
    For i=0:  return sum - 2*sb0     where sum = sb0 + s1 + ... + s15
    For i=1:  return s1 + sum
    For i>=2: return V[i] * s_i + sum
    """
    helpers = []
    for i in range(16):
        fn_name = f"partial_round_out_{i:02d}"
        # Args: sb0, s1, ..., s15
        params = ["sb0: u32"] + [f"s{p:02d}: u32" for p in range(1, 16)]
        params_str = ", ".join(params)
        requires = ["requires sb0 < BABY_BEAR_P"] + [
            f"requires s{p:02d} < BABY_BEAR_P" for p in range(1, 16)
        ]
        requires_str = "\n    ".join(requires)
        lines = []
        lines.append("#[device]")
        lines.append(f"fn {fn_name}({params_str}) -> u32")
        lines.append(f"    {requires_str}")
        lines.append("    ensures result < BABY_BEAR_P")
        lines.append("{")
        # Compute sum.
        lines.append("    let s_a: u32 = baby_bear_add(sb0, s01);")
        lines.append("    let s_b: u32 = baby_bear_add(s_a, s02);")
        lines.append("    let s_c: u32 = baby_bear_add(s_b, s03);")
        lines.append("    let s_d: u32 = baby_bear_add(s_c, s04);")
        lines.append("    let s_e: u32 = baby_bear_add(s_d, s05);")
        lines.append("    let s_f: u32 = baby_bear_add(s_e, s06);")
        lines.append("    let s_g: u32 = baby_bear_add(s_f, s07);")
        lines.append("    let s_h: u32 = baby_bear_add(s_g, s08);")
        lines.append("    let s_i: u32 = baby_bear_add(s_h, s09);")
        lines.append("    let s_j: u32 = baby_bear_add(s_i, s10);")
        lines.append("    let s_k: u32 = baby_bear_add(s_j, s11);")
        lines.append("    let s_l: u32 = baby_bear_add(s_k, s12);")
        lines.append("    let s_m: u32 = baby_bear_add(s_l, s13);")
        lines.append("    let s_n: u32 = baby_bear_add(s_m, s14);")
        lines.append("    let sum: u32 = baby_bear_add(s_n, s15);")
        # Now compute the i-th output.
        if i == 0:
            # sum - 2*sb0
            lines.append("    let two_sb0: u32 = baby_bear_double(sb0);")
            lines.append("    baby_bear_sub(sum, two_sb0)")
        elif i == 1:
            lines.append("    baby_bear_add(s01, sum)")
        else:
            v_const = f"V_{i:02d}"
            si = f"s{i:02d}"
            lines.append(f"    let v_si: u32 = baby_bear_mul({si}, {v_const});")
            lines.append("    baby_bear_add(v_si, sum)")
        lines.append("}")
        helpers.append("\n".join(lines))
    return "\n\n".join(helpers)


# -------- Kernel emission --------------------------------------------------

def kernel_lines() -> list[str]:
    lines = []
    lines.append("#[kernel]")
    lines.append("fn baby_bear_fused_perm_factored_kernel(")
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
    lines.append("")

    cur = []
    for i in range(16):
        v = f"s_{i:02d}"
        lines.append(f"        let {v}: u32 = baby_bear_get(state, base + {i}u64);")
        cur.append(v)

    lines.append("")
    lines.append("        // Initial M_E.")
    out_init = []
    for i in range(16):
        v = f"ime_{i:02d}"
        args = ", ".join(cur)
        lines.append(f"        let {v}: u32 = init_ME_out_{i:02d}({args});")
        out_init.append(v)
    cur = out_init

    # Helper to emit one external round.
    def emit_ext_round(label, rc_const_prefix):
        nonlocal cur
        lines.append("")
        lines.append(f"        // External round {label}.")
        # SBOX(state[i] + rc[i]) for i in 0..15.
        sb = []
        for i in range(16):
            v = f"{label}_sb_{i:02d}"
            rc = f"{rc_const_prefix}_{i:02d}"
            lines.append(f"        let {v}: u32 = baby_bear_p2_ext_sbox_with_rc({cur[i]}, {rc});")
            sb.append(v)
        # Apply M_E via the 16 helpers.
        out_round = []
        sb_args = ", ".join(sb)
        for i in range(16):
            v = f"{label}_o_{i:02d}"
            lines.append(f"        let {v}: u32 = ext_round_out_{i:02d}({sb_args});")
            out_round.append(v)
        cur = out_round

    # 4 initial external rounds.
    for r in range(4):
        emit_ext_round(f"ei{r}", f"RC_INIT_{r}")

    # 13 partial rounds.
    for r in range(13):
        lines.append("")
        lines.append(f"        // Partial round {r}.")
        rc = f"RC_INT_{r:02d}"
        sb0_v = f"pr{r}_sb0"
        lines.append(f"        let {sb0_v}: u32 = baby_bear_p2_int_sbox_with_rc({cur[0]}, {rc});")
        # Each partial helper takes (sb0, s1, ..., s15).
        # But wait — for partial_round_out_<i>:
        #   i=0: use sb0 in (sum - 2*sb0). doesn't reference s_i.
        #   i>=1: use s_i and sum.
        # The helper signature is partial_round_out_<i>(sb0, s01..s15).
        # So we pass sb0 plus the 15 unmodified state elements [1..15].
        partial_args = ", ".join([sb0_v] + cur[1:])
        out_round = []
        for i in range(16):
            v = f"pr{r}_o_{i:02d}"
            lines.append(f"        let {v}: u32 = partial_round_out_{i:02d}({partial_args});")
            out_round.append(v)
        cur = out_round

    # 4 terminal external rounds.
    for r in range(4):
        emit_ext_round(f"ef{r}", f"RC_FINAL_{r}")

    lines.append("")
    lines.append("        // Write final state.")
    for i in range(16):
        lines.append(f"        out[base + {i}u64] = {cur[i]};")
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
    out.append("// Fused BabyBear-16 Poseidon2 permutation kernel — FACTORED.")
    out.append("//")
    out.append("// Same byte-identical Plonky3 perm as 2008_*, but the 22 layers")
    out.append("// are factored into 48 per-output-element `#[device]` helpers")
    out.append("// (init_ME_out_<i>, ext_round_out_<i>, partial_round_out_<i>).")
    out.append("// Each helper has bounded SMT (16 inputs, ~30 ops, ~30 obligations),")
    out.append("// so FORGE/Z3 verifies the whole permutation without the quadratic")
    out.append("// state blow-up the monolithic 2008_* form hit.")
    out.append("//")
    out.append("// Generated by tools/gen_fused_factored.py.")
    out.append("")
    out.append("use std::gpu;")
    out.append("use std::baby_bear;")
    out.append("use std::poseidon2_baby_bear;")
    out.append("")
    out.extend(emit_consts())
    out.append("")
    out.append("fn baby_bear_get(arr: span<u32>, idx: u64) -> u32")
    out.append("    requires idx < arr.len")
    out.append("    requires forall k: u64, k < arr.len ==> arr[k] < BABY_BEAR_P")
    out.append("    ensures result < BABY_BEAR_P")
    out.append("{")
    out.append("    assert(arr[idx] < BABY_BEAR_P) \"forall k instantiated at idx\";")
    out.append("    arr[idx]")
    out.append("}")
    out.append("")
    out.append("// ---- Initial M_E helpers (16) ---------------------------------------")
    out.append(emit_M_E_helper("init_ME_out", [f"x{p:02d}" for p in range(16)]))
    out.append("")
    out.append("// ---- External-round output helpers (16) -----------------------------")
    out.append("// Same body as init_ME but the inputs are *post-sbox* values.")
    out.append("// Function shape is identical; we duplicate the names so kernel-side")
    out.append("// reads cleanly.")
    out.append(emit_M_E_helper("ext_round_out", [f"x{p:02d}" for p in range(16)]))
    out.append("")
    out.append("// ---- Partial-round output helpers (16) ------------------------------")
    out.append(emit_partial_helper())
    out.append("")
    out.extend(kernel_lines())
    out.append("")
    out.append("fn main() -> u64 { 0u64 }")
    print("\n".join(out))


if __name__ == "__main__":
    main()
