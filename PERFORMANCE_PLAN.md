# Performance plan: reGTA III (Upstate) and reVC (Metal)

Original plan written 2026-10-18. The evening checkpoints below supersede the initial estimates; Steps 3 and 4 have not started.
Both games share the renderer code (librw-metal `vendor/librw/src/mtl`, `gl3device.cpp`, `src/extras/metalfx/MetalRT.cpp`).
Every step is done once, carried over to the other game and measured in both.

## Starting point (Vice City, 1680x889, RenderScaleIdx=0 = 100%, all RT effects on)

| | MSAA off | MSAA 4x |
|---|---|---|
| FPS | 30 | 30 |
| GPU | 28.8 ms | 31.3 ms |
| "ray tracing" (CPU) | 12.0 ms | 11.4 ms |
| "upscale step" (CPU) | 25.3 ms | 28.0 ms |
| scene CPU | 6.3 ms | 6.8 ms |

- **MSAA stays on.** It costs about 2.5 ms of GPU and visibly helps thin lines (poles, traffic-light arms, wires), which the temporal
  AA and MetalFX cannot rebuild.
- **The GPU (about 30 ms) is nearly the limit of the 33 ms frame.** Speeding up the CPU alone gives only 1–3 FPS; it pays off
  together with the GPU steps.
- **The RT setup takes 11–12 ms of CPU per frame.** After the Oct 16 change it was about 1 ms. There is no GPU wait in the code.
  Suspect: one `useResource` call per BLAS every trace, and the textured-reflection resource lists.

## Step 0: measure (no visual change)

1. GPU timestamps per compute kernel: traceReflections, traceShadows (shadows, AO, GI, lamps), traceSunShafts.
   Today only the render passes are timed.
2. One CPU profile (`sample`) per game at the same spot with the same settings, plus `REGTA_MTLGL_LOG=1` for GPU time per pass.

## Step 1: CPU stall in the ray tracing (est. ~10 ms CPU)

3. Allocate all BLAS from one MTLHeap and call `useHeap` once per frame instead of `useResource` per BLAS.
4. Rebuild the textured-reflection argument and residency lists only when their contents change.

## Step 2: GPU, effects without visible loss (est. 8–13 ms GPU)

5. Resolution per effect:
   - shadows, AO, indirect light and lamps at half resolution (they are soft and averaged over frames)
   - reflections stay at full resolution
6. Sun shafts: 8 samples per frame with a rotating start offset and a history buffer, instead of 32 per frame.
7. Textured reflections: lower mip level for far or rough hits.
8. Skinned characters in the ray tracing:
   - near ones are refitted every frame
   - far ones every other frame

## Step 3: GPU, Metal efficiency, invisible (est. 3–5 ms GPU)

9. Memoryless MSAA attachments resolved at store. Needs fewer encoder breaks inside the scene pass.
10. StoreAction DontCare for targets nobody reads (window depth/stencil); merge the small prep passes.
11. Textures in private storage (lossless compression) with staging uploads.
12. Optional: test render scale 85–90% plus MetalFX plus MSAA against 100%, side by side in the game. Only adopt it if there
    is no visible difference.

## Step 4: CPU (est. 3–5 ms CPU)

13. Fewer draw calls:
    - occlusion culling from the previous frame's depth
    - batching static map geometry per material
    - a careful draw-distance review (`UpstateFarClip=6500`, `LodBoost=3`), without visible pop-in
14. One uniform ring buffer for per-object shader settings, uploading only what changed (instead of 1–5 KB of `setVertexBytes`
    per draw).
15. Metal command recording on a worker thread.
16. Character skinning for the RT on the GPU instead of the CPU.

## Expected result

- GPU: about 30 ms → 15–20 ms
- CPU: about 25 ms → about 10 ms
- About **50–60 FPS** instead of 30, with the same settings and look (about 45 FPS if the GPU savings land at the low end).
- These are estimates. Step 0 replaces them with measured numbers, and the steps with the largest measured gain go first.

## Status 2026-10-18 evening (measured in both games, `REGTA_MTLGL_LOG=1`, timed trace every 240 frames)

Done (both repos, `MetalRT.cpp` identical; all `tools-mtl/rt-*` tests pass):

| Change | Measured effect |
|---|---|
| Residency set instead of per-frame `useResource` | GTA III main thread in `useResource`: 27% → 0.4%; RT CPU per trace 3.8–6.7 → 1.2–3.6 ms |
| Sun shafts: a quarter of the steps per frame + history | GTA III 13–16 → 1.3–3 ms |
| Shadow kernel: skips per 8x4 tile (SIMD-coherent, per-pixel checkerboards saved nothing) | city benchmark 3.97 → 2.52 ms |
| Cars: motion-vector history (owner tag in pos.w), smooth normals, no tile skipping for the sun shadow | no dots/grids/squares on moving paint |
| Reflections: own-car exclusion in one `intersection_query` traversal, dynamic search stops at the map hit | car reflections 7–16 → 3–4 ms (up to 6–10 when cars fill the screen) |
| Indirect light: map 1 tile in 8 per frame, cars in tiles | indirect light 4–6 → 2.4–3.8 ms |
| RT prep: stable sample per reduced block | no shimmering reflections |

Findings that redirect the plan:
- Both games are GPU-bound now (GTA III main thread waits 65% in `nextDrawable`, 3200 draws). Step 4 (CPU) can wait.
- The shadow pass runs about 2x slower "cold" than an identical warm repeat (13–20 vs 7–10 ms): memory latency of the BVH, not ray maths. Cars/peds cost < 1 ms of it with warm caches. The history lookup saves more than it costs (without it the pass doubles).
- MSAA 2x scene: 4 multisample attachments (RGBA8, RGBA32F velocity, RGBA16F reflection, depth32F+S8) = about 66 B/pixel stored and re-read by the resolve, ~3 ms of bandwidth. A tile-shader resolve would need depth in a colour attachment; not started.
- Most GTA III textures are 64x64/128x128 without mips; textured reflection cost is the scattered UV lookups, not texture size.

Remaining options: MSAA tile resolve / smaller velocity format (invisible, ~2–3 ms, large change); 85–90% render scale + MetalFX (visible trade-off, user must compare); BVH layout for cold traversal (research).

## Codex continuation: profiling cleanup before Step 3

Claude's renderer optimizations are preserved in both ports. Current shared librw source files and MetalRT.cpp match byte for byte between the two games. Preserve current 90 percent render scale and 4x MSAA; this continuation changes neither settings nor GPU kernel source.

Basic `REGTA_MTLGL_LOG=1` now records the three kernel encoder intervals every 240 traces without the nine extra counterfactual dispatches, per-pixel atomic statistics or forced dynamic tree rebuild. The old expensive investigation is available only with **both** `REGTA_MTLGL_LOG=1 REGTA_RT_DIAGNOSTICS=1`. Diagnostic shadow outputs now use independent scratch textures rather than aliasing three writable outputs. Resources are released at shutdown. Timestamp parsing checks returned size and both counter error values. Logs label these as serial profiling samples and also report total command-buffer GPU duration.

Validation: an offscreen fixture invokes production mrtTrace in normal, basic, detailed and diagnostic-without-logging modes. Outputs for reflections, shadows, lighting and sun shafts are byte-identical across all four; basic mode keeps dynamic refits and allocates no diagnostic scratch textures. Separate moving-vehicle history, shadow history and sun-shaft regressions pass. These results do NOT establish a new gameplay FPS figure or prove the old 13–26 ms shaft spikes were purely a counter artifact. They remove a confirmed profiling workload and make the next comparison cleaner.

Live evidence inspected: both games already have per-kernel/CPU trace logs. Latest retained III CPU trace sections were about 1.70–1.82 ms; VC about 0.72–0.87 ms, from different scenes. They are not a matched-location comparison. A new controlled same-scene test in each game remains needed after installation. Do not start games or capture screens without a current user request.

Remaining before claiming performance acceptance: user gameplay retest with basic logging, confirming frame times, sun-shaft spikes, stable reflections and moving-car history. The cold-versus-warm BVH finding remains open. Independent per-effect reflection/shadow resolution and distant-character update scheduling are still proposals, not automatically checked off because other Step 2 changes landed.

Step 3 stays pending this checkpoint. Audit attachment lifetimes before any discard or memoryless conversion: window/HUD depth was previously involved in the radar masking bug. Do not assume memoryless MSAA is free or discard depth simply because a plan says it is unused. The rejected zebra-pattern scratch effect remains FAILED and deferred in the separate vehicle plan; map/airport work remains gated.
