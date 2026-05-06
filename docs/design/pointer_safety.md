# Pointer Safety in Forge — Design Proposal

Status: **proposal — not yet implemented**.
Owner: garrick.
Related: ROADMAP_KERNEL.md Tier 1 ("Raw pointers + arithmetic — Status: Partial").

## What we have today

`raw<T>` exists in the AST (`TRaw`) and emits `T*` in C codegen. The
codegen-side intrinsics (`ptr_read`, `ptr_write`, `ptr_offset`, `ptr_null`,
`ptr_to_u64`, `u64_to_ptr`) are wired through but **carry zero proof
obligations**: a `ptr_read(p)` will type-check unconditionally, including
when `p` is `null` or dangling. They are unsafe-by-construction escape
hatches with no abstract memory model behind them.

## What we want

Pointer ops with proof obligations strong enough that kernel modules,
allocators, and DMA harnesses can be verified without dropping into
`assume()`. Concretely:

- `ptr_read(p)`        ⇒ obligation `p != null && valid_for(p, T)`.
- `ptr_write(p, v)`    ⇒ same, plus a write-effect tracked by the proof
                          system so subsequent reads can be reasoned about.
- `ptr_offset(p, n)`   ⇒ obligation that `p + n*sizeof(T)` lies inside the
                          same allocation as `p`.
- `ptr_to_u64`/`u64_to_ptr` ⇒ explicitly unsafe; require an `assume()`
                          from the user.

The stretch: distinguish read-only vs read-write vs uninitialized memory.

## Three memory models we could choose

The choice of memory model determines what proof obligations look like and
how much Forge has to teach Z3. None of these are free — pick the one
whose verification cost matches the use cases we care about.

### A. Flat byte heap (single global memory)

Everything lives in one big address space; pointers are offsets;
`valid_for(p, T)` is a length-bound predicate against a global "size of
heap" axiom. Roughly:

```
axiom heap_size: u64
predicate live(p: u64, n: u64) := p + n <= heap_size
```

Pros:
- Simple to model; one Z3 sort (Int) covers it.
- Plays well with VortexSTARK-style monolithic GPU buffers where all
  arrays are slices of one big device allocation.

Cons:
- No way to express disjoint allocations. `free(p)` and a stale `p` can't
  be distinguished from a valid `p` to a different object.
- Aliasing is unrestricted: every pointer might point to every byte.

When this is enough: pure compute kernels operating on a known array.
Roughly what we already have via `span<T>`, just lower-level.

### B. Block-with-offset (CompCert-style)  ←  recommended

Each allocation is a fresh "block id"; a pointer is `(block_id, offset)`.
Two pointers from different blocks are provably non-aliasing without
extra reasoning. Validity is per-block:

```
sort block_id
function size_of: block_id -> u64
predicate live(b: block_id, o: u64, n: u64) := o + n <= size_of(b)
```

Pros:
- Aliasing reasoning is tractable: distinct `block_id`s ⇒ disjoint memory.
  Z3 handles this natively.
- Maps well onto allocator semantics: each `alloc()` returns a new block.
- Used successfully by CompCert and several verified kernels — known to
  scale.

Cons:
- Codegen has to keep block-id metadata around at proof time but erase it
  for emission. Forge already erases proof witnesses, so this is the same
  pattern as type-erased generics.
- `ptr_to_u64` becomes lossy: the resulting integer cannot recover its
  block id, so converting back is unsafe (must assume).

When this is enough: allocators, kernel modules with multiple
independently-managed buffers, anything where "is this a fresh
allocation" matters.

### C. Separation logic regions

Pointers carry a region capability; operations consume/produce
capabilities; framing is implicit. Most expressive, most painful.

Pros:
- Best support for ownership transfer, linear protocols, concurrent
  patterns.
- Already-verified projects (Verus, Iris) have shown it scales to OS
  kernels.

Cons:
- Significant compiler + Z3 work. Forge's existing linear-type machinery
  (`OLinear`) handles single-owner patterns but doesn't yet model
  separated heap fragments.
- Realistic minimum-viable cost: weeks of compiler work plus a Forge
  prelude exposing the separation primitives.

When this is enough: anything (B) covers, plus full ownership transfer
semantics. Probably overkill for the GPU-compute use cases that are the
near-term consumers.

## Recommendation

Go with **(B), block-with-offset**. It buys us the property we actually
need (disjoint allocations imply non-aliasing) without committing to a
separation-logic rewrite, and it has a track record.

## Proposed implementation steps for (B)

1. **AST + types**
   - Keep `TRaw t` as the surface type.
   - Add a hidden `TBlock t` (proof-only) carrying block-id metadata. The
     type checker introduces `TBlock t` for pointers obtained from
     `alloc<T>()` and tracks them through `ptr_offset`. Codegen erases
     `TBlock` back to `TRaw` (== `T*`).

2. **Allocation primitive**
   - Add `alloc<T>(n: u64) -> raw<T>` with a fresh-block postcondition:
     `ensures size_of(block_of(result)) == n`.
   - Add `free(p: raw<T>)` with precondition `p != null` and effect
     "block becomes dead" (track in proof env).

3. **Obligations**
   - New `obligation_kind`: `OPointerLive of string` (the pointer name).
   - `ptr_read(p)`  ⇒ obligation `live(block_of(p), offset_of(p), sizeof(T))`.
   - `ptr_write(p, v)` ⇒ same, plus update env's "last written value"
     fact.
   - `ptr_offset(p, n)` ⇒ obligation that the offset stays inside the
     block.

4. **Z3 encoding**
   - Add an uninterpreted sort `Block` and uninterpreted `block_of`,
     `offset_of`, `size_of` functions.
   - Emit axioms about freshly-allocated blocks (block id distinct from
     all prior).

5. **Codegen**
   - `alloc<T>(n)` ⇒ `(T*)malloc(n * sizeof(T))` for host code,
     `cudaMalloc(...)` for device code (with the right runtime selection
     based on `#[device]`/`#[kernel]` attribute).
   - `free` ⇒ `free` / `cudaFree`.
   - Block-ids are erased.

6. **Test demos**
   - Walk through allocator, simple linked list, two-buffer DMA pattern.
   - Add `demos/bad/` cases that should fail: use-after-free, bound
     overrun, null deref.

## Rough scope estimate

| Step                         | Effort  |
|------------------------------|---------|
| AST + alloc/free intrinsics  | half day |
| Obligation generation        | 1 day   |
| Z3 axiomatization            | 1 day   |
| Codegen (host + device)      | half day |
| Demos + CI                   | half day |
| **Total**                    | ~3.5 days |

Doubles if we hit edge cases in `ptr_to_u64`/`u64_to_ptr` round-trips,
which we should probably leave as `assume()`-only operations for v1.

## Out of scope for v1

- Concurrent access invariants (would require region-based reasoning).
- Type punning across pointer casts (a `raw<u32>` cast to `raw<u8>` is
  legal at the C level but not modeled here).
- Custom allocators inside Forge (we just provide the `alloc`/`free`
  surface; backing implementation is C runtime).

## Open questions for the user

1. Are the GPU-compute use cases enough to justify (B), or is (A) enough
   for now? VortexSTARK currently uses one big device buffer; if all near-
   term consumers look like that, (A) is cheaper.
2. Should `alloc` be a Forge intrinsic or live behind an explicit
   `extern fn alloc<T>(n: u64) -> raw<T> = "forge_runtime"`? The latter
   keeps it out of the proof core.
3. Do we want a separate `dealloc` proof obligation, or treat `free(p)`
   as "trust the user" for v1?

Until these are answered I'm treating the design as "ready to start once
we agree on (A) vs (B)".