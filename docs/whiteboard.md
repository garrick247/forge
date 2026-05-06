# Forge / GPU-stack whiteboard

Living tracker of outstanding work. Updated as items land. Append; do not
silently delete history (mark items resolved with date + PR).

## Tier 1 — CI hygiene across the stack

- [x] ~~**openptxas/corpus.yml**~~: ported to Linux self-hosted runner
      with sibling forge-workbench install + cross-platform CUDA loader.
      One kernel (`w2_nested_loop`) hangs the GPU on `cuCtxSynchronize`
      and is allowlisted in `scripts/known_fail.txt` — separate codegen
      bug, see Tier 5. (openptxas PR #1, 2026-05-06.)
- [ ] **VortexSTARK/ci.yml gpu-tests**: hardcoded `/home/runner/.cargo/bin`
      — runner user is `garrick`, not `runner`. Update PATH.
- [ ] **VortexSTARK + Rust toolchain on the runner**: rustup not yet
      installed system-wide; cargo workflow will fail on first run unless
      we either provision rustup or have the workflow install it per run.

## Tier 2 — Forge codegen bugs

Currently 1 quarantined demo (down from 8). Each fails `gcc -fsyntax-only`
with a real C error. Listed in `KNOWN_CODEGEN_BUG_RE` in `test/run_all.sh`.

- [x] ~~**1045_old_span_field**~~: span<UserStruct> typedef ordering. Fixed
      by a forward-typedef pass in `emit_program` (PR forthcoming).
- [x] ~~**58_modules.c, 62_for_in_iter.c, 64_std_iter.c, 68_enum_methods.c,
      71_builder_pattern.c, 77_match_guards.c, 78_nested_match.c**~~:
      fixed via call-site-driven generic-fn elision (2026-05-06). The
      problem: `use std::option;` pulls in `is_some<T>`, `unwrap_or<T>`
      etc. that the demos never call; they emitted as broken forward
      decls AND name-collided across modules (std::option::unwrap_or vs
      std::result::unwrap_or both erased to `void* unwrap_or(...)`).
      Generic fns now emit only if called by name in some non-generic
      body; the existing void-erasure of T at `emit_ty` handles the
      called ones (demo 73 hash_inline with ref-T parameter and friends).
      Per-call-site monomorphization with type substitution remains
      future work for any demo that needs to *call* an Option<T>
      stdlib helper directly — see Tier 5.
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
- [x] ~~**Bitwise column demux** (Phase 4 in ANALYSIS.md)~~: kernels now
      take `log_half_n` / `log_n` and use `tid >> log_*` + `tid & (n - 1)`.
      Forge re-verified at 145 obligations (down from 148, all discharged,
      0 assumes); VortexSTARK shim updated to compute log via
      `__builtin_ctz`. (PR forthcoming, 2026-05-06.)

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

- [ ] Per-call-site generic-function monomorphization with type
      substitution. The current call-site-driven elision (2026-05-06)
      handles all demos in the corpus, but a future demo that calls an
      Option<T> stdlib helper directly would still hit broken `void`
      params for bare-T positions. Plan: walk ECall sites, build
      (callee, [ty_args]) set, emit one mangled copy per pair via a
      substituting body walker. Plan-agent design exists in chat
      history; estimate ~1 day.
- [ ] Move the `KNOWN_CODEGEN_BUG_RE` quarantine list out of `run_all.sh`
      into a tracked allowlist file.
- [ ] Rust toolchain (`rustup`/`cargo`) on the runner box for VortexSTARK.
- [ ] CUDA toolkit (`nvcc`, `ptxas`) — driver alone does not ship the
      compiler.
- [ ] **openptxas `w2_nested_loop` codegen**: kernel SASS hangs the GPU
      on `cuCtxSynchronize` (15s subprocess timeout in `corpus_sweep.py`).
      Allowlisted in `openptxas/scripts/known_fail.txt`. Currently
      single-kernel quarantine; root-cause + fix unknown.

## Done (most-recent first)

- ✅ 2026-05-06 Phase 4 bitwise column demux on batch NTT (PRs forthcoming)
- ✅ 2026-05-06 generic-fn elision: 7 demos out of quarantine (PR forthcoming)
- ✅ 2026-05-06 openptxas PR #1: corpus workflow + sweep ported to Linux runner
- ✅ 2026-05-06 4-layer fused NTT + 1045 codegen fix (PR forthcoming)
- ✅ 2026-05-06 PR #4: 2-layer fused NTT + pointer-safety design proposal
- ✅ 2026-05-06 PR #3: parallel test suite (18m → 1m53s) + demo 823 fix
- ✅ 2026-05-05 6 per-repo runners registered + minimal CI on 4 repos
- ✅ 2026-05-05 PR #2: GitHub Actions workflow on self-hosted GPU runner
- ✅ 2026-05-05 PR #1: bitfield obligations + warp NTT layer + use-resolver