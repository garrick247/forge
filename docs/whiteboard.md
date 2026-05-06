# Forge / GPU-stack whiteboard

Living tracker of outstanding work. Updated as items land. Append; do not
silently delete history (mark items resolved with date + PR).

## In flight

_(none — start a fresh attack here when picking up an item)_

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

## Tier 2 — Forge codegen bugs (the 9 quarantined .c files)

Each one fails `gcc -std=c99 -fsyntax-only` with a real C error. Currently
listed in `KNOWN_CODEGEN_BUG_RE` so CI is honest. Goal: fix the codegen,
remove from the regex, drop CI failure tolerance.

- [ ] **58_modules.c, 62_for_in_iter.c, 64_std_iter.c**: generic type
      parameters `T`/`U` leak to C as raw identifiers (`T _v0;`). Single
      root-cause fix in `lib/codegen/codegen_c.ml` likely covers all three.
- [ ] **1044_float_smt.c**: `return f(v);` where `f` has fn-pointer type
      but C codegen emits it without `(*f)(v)` syntax. TFn codegen path.
- [ ] **1045_old_span_field.c**: probably the legacy `.field` access on
      span<T>; may be deprecated syntax to remove from demos rather than
      fix codegen. Investigate first.
- [ ] **68_enum_methods.c**: enum-method dispatch.
- [ ] **71_builder_pattern.c**: builder-pattern synthesis.
- [ ] **77_match_guards.c**: match guard codegen.
- [ ] **78_nested_match.c**: nested match.

## Tier 3 — NTT optimization (Phase 3 continuation)

- [x] 2-layer fused warp NTT — `circle_ntt_warp_fused2.fg` (PR #4).
- [ ] **4-layer fused warp NTT**: mechanical extension; stride <= 2 keeps
      everything inside a warp, no shared memory needed.
- [ ] **8-layer fused via shared memory**: full Phase 3. Needs Forge
      modeling of `shared<T>[N]` writes + `__syncthreads()` barriers.
      Substantial — should be its own design doc once we tackle it.
- [ ] **Bitwise column demux** (Phase 4 in ANALYSIS.md): replace `tid /
      half_n` and `tid % half_n` in the batch kernel with bit ops.
      10-20% on batch NTT; trivial change.

## Tier 4 — Pointer safety (the big one)

Per `docs/design/pointer_safety.md`. Memory model: block-with-offset.
Open questions resolved in the user's "everything" instruction:
- (1) Block-with-offset (recommended in the doc).
- (2) `alloc`/`free` as `extern fn ... = "forge_runtime"` (keeps proof
  core clean).
- (3) v1 tracks block-death (more rigorous; "trust the user" is too
  loose for kernel verification).

- [ ] **Slice 1**: AST + alloc/free intrinsics + `OPointerLive`
      obligation kind. Half day.
- [ ] **Slice 2**: Z3 axiomatization (sort `Block`, functions
      `block_of`/`offset_of`/`size_of`, freshness axiom). Day.
- [ ] **Slice 3**: obligation generation in typecheck for `ptr_read`,
      `ptr_write`, `ptr_offset`. Day.
- [ ] **Slice 4**: codegen — `alloc<T>(n)` → `(T*)malloc(n*sizeof(T))`,
      device variants → `cudaMalloc`. Half day.
- [ ] **Slice 5**: demos (positive + bad), CI integration. Half day.

## Tier 5 — Followups noted along the way

- [ ] Move the `KNOWN_CODEGEN_BUG_RE` quarantine list out of `run_all.sh`
      into a tracked allowlist file (`test/known_codegen_bugs.txt`)
      reviewed in CI.
- [ ] `q1.ml`/`q2.mli` editor backups recurring? Add to `.gitignore` as a
      preventive measure.
- [ ] Rust toolchain (`rustup`/`cargo`) needs installing on the runner
      box before VortexSTARK CI can pass on the gpu-tests job.
- [ ] CUDA toolkit (`nvcc`, `ptxas`) — currently relying on bundled NVIDIA
      driver bits; some workflows may need explicit `cuda-toolkit-12-x`
      install for `nvcc` (the driver alone doesn't ship the compiler).

## Done

- ✅ 2026-05-05 PR #1: bitfield obligations + warp NTT layer + use-resolver
- ✅ 2026-05-05 PR #2: GitHub Actions workflow on self-hosted GPU runner
- ✅ 2026-05-05 PR #3: parallel test suite (18m → 1m53s) + demo 823 fix
- ✅ 2026-05-06 PR #4: 2-layer fused NTT + pointer-safety design proposal
- ✅ 2026-05-06 6 per-repo runners registered + minimal CI on 4 repos