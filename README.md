# reVC Metal for Apple Silicon

Native Vice City build kit with a Metal renderer, MetalFX temporal upscaling, ray-traced reflections/shadows/lighting and volumetric sun rays, MSAA, native Modloader/add-on cars, trainer/free roam, local vehicle deformation and imported running-gear animation. No game data or converted cars included. Requires your own compatible Vice City data and authors' permission for any mods you use.

This repository contains reproducible patches against pinned upstream source, not executable releases. Run `./build.sh` on macOS with Xcode command-line tools and Homebrew. It fetches source-only dependencies and builds `source/build-metal/src/reVC`. Game launch/install is manual; stop the game, back up your executable and sign the copied binary with `codesign -f -s - reVC_metal`.

The converter is a separate repository: https://github.com/mindingulove/iv-vc-car-converter . Put its checkout alongside a `revc-metal` source checkout for native asset validation, or configure the source location as described there.

See the applied source's `docs/SUN_RAYS_AND_MSAA.md` and `PORT_STATUS.md`. GPU fixture success does not prove gameplay appearance/performance. Existing pane-depth/occupant reflection defects, complete vehicle visual acceptance and the long-running ANE framework abort remain open. M1 supports real native 2x/4x MSAA; 8x/16x requests fall back to actual supported samples. High render scale improves full-image sharpness at greater GPU cost.

Upstream reVC's licensing/credits remain those of its original authors (read upstream README). The librw Metal derivative retains the upstream MIT license. This kit does not grant rights to Rockstar game assets or third-party car mods. No secrets, extracted textures/models, caches or source-pack archives are included.

## Current gameplay evidence

[User-provided screenshots and unresolved visual/performance reports](docs/GAMEPLAY_BUG_EVIDENCE.md). Higher asset detail and added lighting features are not proof of a better overall experience: window artifacts, wet-road ghosting and poor frame rate remain open.
