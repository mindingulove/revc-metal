# reVC Metal for Apple Silicon

Native Vice City build kit with a Metal renderer, MetalFX temporal upscaling, ray-traced reflections/shadows/lighting and volumetric sun rays, MSAA, native Modloader/add-on cars, trainer/free roam, local vehicle deformation and imported running-gear animation. No game data or converted cars included. Requires your own compatible Vice City data and authors' permission for any mods you use.

This repository contains reproducible patches against pinned upstream source, not executable releases. **[Follow the installation guide](docs/INSTALL.md)** to build the engine and use it with your own Vice City PC game files. The guide covers prerequisites, copying game data, engine support files, signing, launching, updates and optional converted cars.

The Metal backend and native mod code come from the RegTA Upstate port. `build.sh` fetches the Vice City/reVC engine tree and its librw dependency at pinned commits, then applies these patches. You do not need an existing RegTA installation. GTA III/Upstate data belongs to the separate GTA III port; this engine requires Vice City data.

The converter is a separate repository: https://github.com/mindingulove/iv-vc-car-converter . Put its checkout alongside a `revc-metal` source checkout for native asset validation, or configure the source location as described there.

See the applied source's `docs/SUN_RAYS_AND_MSAA.md` and `PORT_STATUS.md`. GPU fixture success does not prove gameplay appearance/performance. Pane receiver depth and current-frame road reflection fixes are implemented and pass native fixtures; their gameplay appearance/performance, complete vehicle visual acceptance and the long-running ANE framework abort remain open. M1 supports real native 2x/4x MSAA; 8x/16x requests fall back to actual supported samples. High render scale improves full-image sharpness at greater GPU cost.

Upstream reVC's licensing/credits remain those of its original authors (read upstream README). The librw Metal derivative retains the upstream MIT license. This kit does not grant rights to Rockstar game assets or third-party car mods. No secrets, extracted textures/models, caches or source-pack archives are included.

## Current gameplay evidence

[User-provided screenshots and unresolved visual/performance reports](docs/GAMEPLAY_BUG_EVIDENCE.md). Higher asset detail and added lighting features are not proof of a better overall experience: window artifacts, wet-road ghosting and poor frame rate remain open.


The latest source includes lossless dynamic scene refit, precise vehicle pane depth, current-frame wet-road/glass reflection composition, actual GPU timing and imported physical lamp-lens shattering support. Reflection resolution, geometry, rays and temporal/MSAA settings are preserved. See `docs/REFLECTION_FIXES.md` in the patched source for validation and memory-cost limits. Converter packages must be regenerated for lamp-lens support; visible fragment behaviour has not been accepted in gameplay.

The 03:21 gameplay screenshots still showed blue panes after the first depth fix. The latest source separates dielectric glass Fresnel from opaque paint clear coat and fixes reversed pane normals. Native pixel tests pass; gameplay acceptance remains open.

Performance fix parity is audited in the patched source `docs/PERFORMANCE_PARITY.md`: opt-in text logging, requested Retina sizing, traced-reflection environment-map bypass, event-driven mouse hover, legacy-shadow selection and HUD depth clearing are present. Metal and OpenGL builds pass; this is not a measured gameplay FPS gain.


## October 18 performance checkpoint

The source includes persistent ray-tracing residency, temporally accumulated sun shafts, coherent shadow/GI tile scheduling, motion-vector vehicle history, stable reflection preparation and footprint-based reflected texture mip selection. The accompanying source defaults request 90% render scale and 4x MSAA; existing user settings are retained. Historical gameplay figures are in [PERFORMANCE_PLAN.md](PERFORMANCE_PLAN.md), not a promise of FPS on another machine.

Basic `REGTA_MTLGL_LOG=1` records CPU sections and three kernel encoder times every 240 traces. Expensive repeats/counters/rebuild experiments now additionally require `REGTA_RT_DIAGNOSTICS=1`. Timed frames use serialized encoder samples; normal rendering remains concurrent. A production no-window fixture checks identical output with logging off/basic/detailed and resource cleanup. See `docs/RT_PROFILING.md` in the reconstructed source.

Step 3 (memoryless attachments/store actions/private textures) and CPU threading remain pending. Sun-shaft spikes and cold-cache traversal still need controlled gameplay measurements. The zebra-pattern scratches failed user review; their contact-driven replacement is deferred. No world/map conversion is included. Build/fixture results do not establish gameplay visual acceptance.

Validation for this checkpoint: reconstructed the pinned upstream source with the published patch/library inputs and completed a clean Metal build for each game. All four local OpenGL/Metal executables built and were installed while stopped with signature checks, backups and unchanged INI hashes. No game was launched. A new gameplay performance comparison is pending.
