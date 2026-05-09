#!/usr/bin/env python3
"""Emit a fused BB-16 Poseidon2 .fg (chained-SSA monolithic form).

This form is documented as **NOT verifiable** by the current FORGE/Z3
pipeline — chained let-bindings across 22 layers blow up SMT state
quadratically. See tools/gen_fused_factored.py and gen_fused_per_round.py
for the verifiable variants. Kept for reference / scratch use; route
output to demos/_tmp_<name>.fg so the test runner skips it.

Holds 16-felt state in chained let-bindings (SSA-style) across all 22
permutation layers (1 init M_E + 4 ext + 13 partial + 4 ext). RCs and
diagonal V values match Plonky3's BABYBEAR_POSEIDON2_RC_16_* exactly,
so the kernel computes byte-identical permutations to Plonky3 reference.
"""
from __future__ import annotations

P = 2013265921  # BabyBear prime: 2^31 - 2^27 + 1

# -- Plonky3's RCs from baby-bear/src/poseidon2.rs ---------------------------

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

# -- BB-16 internal-layer diagonal V from Plonky3 ----------------------------
# V = [-2, 1, 2, 1/2, 3, 4, -1/2, -3, -4, 1/2^8, 1/4, 1/8, 1/2^27,
#      -1/2^8, -1/16, -1/2^27]
# We compute the field-element value of each.

def inv(x: int) -> int:
    return pow(x, P - 2, P)

def neg(x: int) -> int:
    return (P - x) % P

V_DIAG = [
    neg(2),       # -2
    1,
    2,
    inv(2),       # 1/2
    3,
    4,
    neg(inv(2)),  # -1/2
    neg(3),
    neg(4),
    inv(256),     # 1/2^8
    inv(4),
    inv(8),
    inv(1 << 27), # 1/2^27
    neg(inv(256)),
    neg(inv(16)), # -1/16
    neg(inv(1 << 27)),
]

# Sanity-check: ensure all values fit in 31 bits and are < P.
for v in V_DIAG:
    assert 0 <= v < P, v
for round in EXT_INIT + EXT_FINAL:
    for v in round:
        assert 0 <= v < P, v
for v in INTERNAL_RC:
    assert 0 <= v < P, v

# -- .fg generation ----------------------------------------------------------

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


def emit_helpers() -> list[str]:
    """Helper for partial-round diagonal mixing.
    Per element i: new_state[i] = V[i] * state[i] + sum   for i != 0
    For i == 0: new_state[0] = sum - 2*state[0]
    We inline these via baby_bear_mul / baby_bear_add / baby_bear_sub.
    """
    return []


def ext_round(prefix: str, in_vars: list[str], rc_consts: list[str]) -> tuple[list[str], list[str]]:
    """Emit one external round: ARK + SBOX + M_E.

    Returns (lines, out_vars) where out_vars is the list of 16 names
    holding the post-round state.
    """
    lines = []
    # 1. ARK + SBOX (combined via p2_ext_sbox_with_rc).
    sbox_vars = []
    for i in range(16):
        v = f"{prefix}_sb_{i:02d}"
        lines.append(
            f"    let {v}: u32 = baby_bear_p2_ext_sbox_with_rc({in_vars[i]}, {rc_consts[i]});"
        )
        sbox_vars.append(v)

    # 2. Apply M_4 to each chunk of 4: c[k][i] = M_4 * (sb[k*4..k*4+4])[i]
    chunk_vars: list[list[str]] = []
    for k in range(4):
        a, b, c, d = sbox_vars[k * 4: k * 4 + 4]
        cy = []
        for j in range(4):
            v = f"{prefix}_c{k}_{j}"
            lines.append(
                f"    let {v}: u32 = baby_bear_p2_ext_chunk_y{j}({a}, {b}, {c}, {d});"
            )
            cy.append(v)
        chunk_vars.append(cy)

    # 3. Column sums across chunks: cs[j] = sum_k c[k][j]
    col_sum = []
    for j in range(4):
        # cs_j = c0_j + c1_j + c2_j + c3_j
        s01 = f"{prefix}_csa_{j}"
        s23 = f"{prefix}_csb_{j}"
        cs = f"{prefix}_cs_{j}"
        lines.append(f"    let {s01}: u32 = baby_bear_add({chunk_vars[0][j]}, {chunk_vars[1][j]});")
        lines.append(f"    let {s23}: u32 = baby_bear_add({chunk_vars[2][j]}, {chunk_vars[3][j]});")
        lines.append(f"    let {cs}: u32 = baby_bear_add({s01}, {s23});")
        col_sum.append(cs)

    # 4. Final: out[k*4 + j] = c[k][j] + cs[j].
    out_vars = []
    for k in range(4):
        for j in range(4):
            v = f"{prefix}_out_{k*4 + j:02d}"
            lines.append(f"    let {v}: u32 = baby_bear_add({chunk_vars[k][j]}, {col_sum[j]});")
            out_vars.append(v)

    return lines, out_vars


def init_M_E(prefix: str, in_vars: list[str]) -> tuple[list[str], list[str]]:
    """Initial linear layer (no ARK, no SBOX) — just M_E applied once."""
    lines = []
    chunk_vars: list[list[str]] = []
    for k in range(4):
        a, b, c, d = in_vars[k * 4: k * 4 + 4]
        cy = []
        for j in range(4):
            v = f"{prefix}_c{k}_{j}"
            lines.append(
                f"    let {v}: u32 = baby_bear_p2_ext_chunk_y{j}({a}, {b}, {c}, {d});"
            )
            cy.append(v)
        chunk_vars.append(cy)
    col_sum = []
    for j in range(4):
        s01 = f"{prefix}_csa_{j}"
        s23 = f"{prefix}_csb_{j}"
        cs = f"{prefix}_cs_{j}"
        lines.append(f"    let {s01}: u32 = baby_bear_add({chunk_vars[0][j]}, {chunk_vars[1][j]});")
        lines.append(f"    let {s23}: u32 = baby_bear_add({chunk_vars[2][j]}, {chunk_vars[3][j]});")
        lines.append(f"    let {cs}: u32 = baby_bear_add({s01}, {s23});")
        col_sum.append(cs)
    out_vars = []
    for k in range(4):
        for j in range(4):
            v = f"{prefix}_out_{k*4 + j:02d}"
            lines.append(f"    let {v}: u32 = baby_bear_add({chunk_vars[k][j]}, {col_sum[j]});")
            out_vars.append(v)
    return lines, out_vars


def partial_round(prefix: str, in_vars: list[str], rc_const: str) -> tuple[list[str], list[str]]:
    """One partial (internal) round.

    1. ARK on state[0] only: a0 = state[0] + rc
    2. SBOX on state[0] only: t0 = sbox_x7(a0)  (4 muls)
    3. Compute sum = t0 + state[1] + ... + state[15] (15 adds)
    4. Apply M_I = I + Diag(V):
         new_state[0]  = sum - 2*t0     (V[0]=-2 → diag entry, but inlined)
         new_state[i]  = V[i]*state[i] + sum  for i in 1..15
    """
    lines = []
    # 1+2. ARK + SBOX on state[0] (uses helper from std/poseidon2_baby_bear.fg).
    t0 = f"{prefix}_t0"
    lines.append(f"    let {t0}: u32 = baby_bear_p2_int_sbox_with_rc({in_vars[0]}, {rc_const});")

    # 3. sum = t0 + state[1..15]  (do as binary tree: 4 partial sums, then 1 final)
    # We just do a left-fold for simplicity.
    s_prev = t0
    for i in range(1, 16):
        s_new = f"{prefix}_sum_{i:02d}"
        lines.append(f"    let {s_new}: u32 = baby_bear_add({s_prev}, {in_vars[i]});")
        s_prev = s_new
    sum_var = s_prev

    # 4. Apply diagonal M_I:
    #    new_state[0] = sum - 2*t0 = sum + (-2*t0)
    #      Compute as: double_t0 = baby_bear_double(t0); negd = baby_bear_neg(double_t0);
    #                  new_0 = baby_bear_add(sum_var, negd)
    out_vars = [None] * 16  # type: ignore
    d2_t0 = f"{prefix}_d2_t0"
    nd2_t0 = f"{prefix}_nd2_t0"
    lines.append(f"    let {d2_t0}: u32 = baby_bear_double({t0});")
    lines.append(f"    let {nd2_t0}: u32 = baby_bear_neg({d2_t0});")
    lines.append(f"    let {prefix}_pr_00: u32 = baby_bear_add({sum_var}, {nd2_t0});")
    out_vars[0] = f"{prefix}_pr_00"

    # i=1..15: new_state[i] = V[i] * state[i] + sum
    # V[1] = 1, so new_state[1] = state[1] + sum (no mul)
    # V[2] = 2, V[4] = 3, V[5] = 4 → can do via doubles+adds (we use baby_bear_mul anyway for clarity)
    # All others use baby_bear_mul.
    for i in range(1, 16):
        v_const = f"V_{i:02d}"
        if i == 1:
            # V[1] = 1, skip mul
            v_state_times_v = in_vars[i]
        else:
            v_state_times_v = f"{prefix}_vmul_{i:02d}"
            lines.append(f"    let {v_state_times_v}: u32 = baby_bear_mul({in_vars[i]}, {v_const});")
        out = f"{prefix}_pr_{i:02d}"
        lines.append(f"    let {out}: u32 = baby_bear_add({v_state_times_v}, {sum_var});")
        out_vars[i] = out

    return lines, out_vars


def emit_kernel() -> list[str]:
    """Emit the full fused kernel."""
    lines = []
    lines.append("#[kernel]")
    lines.append("fn baby_bear_fused_perm_kernel(")
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
    lines.append("        // Load 16-felt state from HBM.")

    cur = []
    for i in range(16):
        v = f"        s_in_{i:02d}"
        lines.append(f"        let s_in_{i:02d}: u32 = baby_bear_get(state, base + {i}u64);")
        cur.append(f"s_in_{i:02d}")

    lines.append("")
    lines.append("        // Initial linear layer (M_E only).")
    init_lines, cur = init_M_E("ime", cur)
    lines.extend([f"    {ln}" for ln in init_lines])  # extra indent

    lines.append("")
    lines.append("        // 4 initial external rounds.")
    for r in range(4):
        rc = [f"RC_INIT_{r}_{i:02d}" for i in range(16)]
        rl, cur = ext_round(f"ei{r}", cur, rc)
        lines.append(f"        // External-initial round {r}.")
        lines.extend([f"    {ln}" for ln in rl])

    lines.append("")
    lines.append("        // 13 partial rounds.")
    for r in range(13):
        rc = f"RC_INT_{r:02d}"
        rl, cur = partial_round(f"pr{r}", cur, rc)
        lines.append(f"        // Partial round {r}.")
        lines.extend([f"    {ln}" for ln in rl])

    lines.append("")
    lines.append("        // 4 terminal external rounds.")
    for r in range(4):
        rc = [f"RC_FINAL_{r}_{i:02d}" for i in range(16)]
        rl, cur = ext_round(f"ef{r}", cur, rc)
        lines.append(f"        // External-final round {r}.")
        lines.extend([f"    {ln}" for ln in rl])

    lines.append("")
    lines.append("        // Write final state back to HBM.")
    for i in range(16):
        lines.append(f"        out[base + {i}u64] = {cur[i]};")
    lines.append("    }")
    lines.append("}")
    return lines


def main() -> None:
    lines = []
    lines.append("// Fused BabyBear-16 Poseidon2 permutation kernel.")
    lines.append("//")
    lines.append("// Each thread runs one full permutation: 16-felt state held in")
    lines.append("// chained let-bindings across all 22 layers (1 init M_E + 4 ext +")
    lines.append("// 13 partial + 4 ext). RCs and diagonal V exactly match Plonky3's")
    lines.append("// BABYBEAR_POSEIDON2_RC_16_* + BabyBearInternalLayerParameters,")
    lines.append("// so this computes byte-identical permutations to the Plonky3")
    lines.append("// reference (default_babybear_poseidon2_16).")
    lines.append("//")
    lines.append("// This file is generated by tools/gen_fused_perm.py.")
    lines.append("")
    lines.append("use std::gpu;")
    lines.append("use std::baby_bear;")
    lines.append("use std::poseidon2_baby_bear;")
    lines.append("")
    lines.extend(emit_consts())
    lines.append("")
    lines.append("fn baby_bear_get(arr: span<u32>, idx: u64) -> u32")
    lines.append("    requires idx < arr.len")
    lines.append("    requires forall k: u64, k < arr.len ==> arr[k] < BABY_BEAR_P")
    lines.append("    ensures result < BABY_BEAR_P")
    lines.append("{")
    lines.append("    assert(arr[idx] < BABY_BEAR_P) \"forall k instantiated at idx\";")
    lines.append("    arr[idx]")
    lines.append("}")
    lines.append("")
    lines.extend(emit_kernel())
    lines.append("")
    lines.append("fn main() -> u64 { 0u64 }")

    print("\n".join(lines))


if __name__ == "__main__":
    main()
