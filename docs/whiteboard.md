# Forge / GPU-stack whiteboard

Living tracker of outstanding work. Updated as items land. Append; do not
silently delete history (mark items resolved with date + PR).

## Tier 1 — CI hygiene across the stack

- [ ] **openptxas/corpus.yml**: references dead `garrick99/forge-workbench`,
      Windows PowerShell + `C:\Users\kraken\...` paths. Repurpose for the
      Linux-native runner (label `[self-hosted, gpu, sm_120]` already
      registered). Convert `pwsh` step to bash, install sibling deps from
      `/home/garrick/forge-workbench`.
- [ ] **VortexSTARK/ci.yml gpu-tests**: hardcoded `/home/runner/.cargo/bin`
      — runner user is `garrick`, not `runner`. Update PATH.
- [ ] **VortexSTARK + Rust toolchain on the runner**: rustup not yet
      installed system-wide; cargo workflow will fail on first run unless
      we either provision rustup or have the workflow install it per run.

## Tier 2 — Forge codegen bugs

Currently 8 quarantined demos (down from 9). Each fails `gcc -fsyntax-only`
with a real C error. Listed in `KNOWN_CODEGEN_BUG_RE` in `test/run_all.sh`.

- [x] ~~**1045_old_span_field**~~: span<UserStruct> typedef ordering. Fixed
      by a forward-typedef pass in `emit_program` (PR forthcoming).
- [ ] **58_modules.c, 62_for_in_iter.c, 64_std_iter.c, 68_enum_methods.c,
      71_builder_pattern.c, 77_match_guards.c, 78_nested_match.c**:
      **all blocked by the same root cause** — generic functions are
      emitted with un-substituted type-param names (T, U, E, F, ...) in
      forward decls + bodies. Fixing requires real **per-call-site
      monomorphization** of generic fns (analogous to how
      `Option<u64>` → `Option_u64` works for enums today). Substantial:
      walk every ECall with type params, mangle the callee name + emit
      a concrete copy with substituted body. Estimate: 1-2 days of
      focused codegen work, plus testing.
- [ ] **1044_float_smt.c**: `return f(v);` where `f` is `(n: u64) -> u64`
      param. Codegen emits `f` as `uint64_t f` rather than as fn-ptr. Also
      blocked by the same monomorphization gap (TFn types don't get a
      typedef + parameter-position translation for generic-context
      function pointers).

## Tier 3 — NTT optimization (Phase 3 continuation)

- [x] 2-layer fused warp NTT — `circle_ntt_warp_fused2.fg` (PR #4).
- [x] 4-layer fused warp NTT — `circle_ntt_warp_fused4.fg` (PR forthcoming).
- [ ] **8-layer fused via shared memory**: full Phase 3. Needs Forge
      modeling of `shared<T>[N]` writes + `__syncthreads()` barriers.
      Substantial — should be its own design doc once we tackle it.
- [ ] **Bitwise column demux** (Phase 4 in ANALYSIS.md): replace `tid /
      half_n` and `tid % half_n` in the batch kernel with bit ops.
      10-20% on batch NTT; trivial change.

## Tier 4 — Pointer safety (the big one)

Per `docs/design/pointer_safety.md`. Memory model: block-with-offset.
Open questions resolved by user's "everything" instruction:
- (1) Block-with-offset.
- (2) `alloc`/`free` as `extern fn ... = "forge_runtime"`.
- (3) v1 tracks block-death.

- [ ] **Slice 1**: AST + alloc/free intrinsics + `OPointerLive`
      obligation kind. Half day.
- [ ] **Slice 2**: Z3 axiomatization (sort `Block`, functions
      `block_of`/`offset_of`/`size_of`, freshness axiom). Day.
- [ ] **Slice 3**: obligation generation in typecheck for `ptr_read`,
      `ptr_write`, `ptr_offset`. Day.
- [ ] **Slice 4**: codegen — `alloc<T>(n)` → `(T*)malloc(n*sizeof(T))`,
      device variants → `cudaMalloc`. Half day.
- [ ] **Slice 5**: demos (positive + bad), CI integration. Half day.

## Tier 5 — Followups

- [ ] Generic-function monomorphization (unblocks 7 of the 8 quarantined
      demos). Big task — separate effort.
- [ ] Move the `KNOWN_CODEGEN_BUG_RE` quarantine list out of `run_all.sh`
      into a tracked allowlist file.
- [ ] Rust toolchain (`rustup`/`cargo`) on the runner box for VortexSTARK.
- [ ] CUDA toolkit (`nvcc`, `ptxas`) — driver alone doesn't ship the
      compiler.

## Done (most-recent first)

- ✅ 2026-05-06 4-layer fused NTT + 1045 codegen fix (PR forthcoming)
- ✅ 2026-05-06 PR #4: 2-layer fused NTT + pointer-safety design proposal
- ✅ 2026-05-06 PR #3: parallel test suite (18m → 1m53s) + demo 823 fix
- ✅ 2026-05-05 6 per-repo runners registered + minimal CI on 4 repos
- ✅ 2026-05-05 PR #2: GitHub Actions workflow on self-hosted GPU runner
- ✅ 2026-05-05 PR #1: bitfield obligations + warp NTT layer + use-resolver