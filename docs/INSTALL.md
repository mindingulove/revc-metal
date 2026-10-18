# Install reVC Metal with your Vice City files

This guide builds the native engine from source and installs it beside a **copy of your own original PC Grand Theft Auto: Vice City game files**. The repository supplies engine patches; it does not supply the commercial game, converted cars or a ready-made game download. Definitive Edition assets are not a supported substitute for the original PC data.

## 1. What you need

- An Apple Silicon Mac, Xcode command-line tools, and Homebrew. The renderer has been built and GPU-tested on Apple M1. MetalFX availability depends on the macOS/SDK version.
- Git and access to this repository and its upstream source repositories. If this repository is private, authenticate with the GitHub account that has access.
- Your complete Vice City PC game directory: retain its `audio`, `anim`, `data`, `models`, `TEXT` and other supplied data directories. Copying only the Windows executable is insufficient.
- A separate destination for the native port, so your original installation remains available.

Install Xcode command-line tools if necessary:

```sh
xcode-select --install
```

Install Homebrew using its official instructions at https://brew.sh if it is not already installed.

## 2. Download and build the engine

```sh
mkdir -p "$HOME/Documents/Code"
cd "$HOME/Documents/Code"
git clone https://github.com/mindingulove/revc-metal.git
cd revc-metal
./build.sh
```

`build.sh` installs the Homebrew build dependencies, downloads the pinned Vice City engine and librw, applies the Metal/native-port patches, and builds:

```text
revc-metal/
  build.sh
  revc-metal.patch
  librw-metal.patch
  source/
    build-metal/src/reVC     <- compiled native executable
    gamefiles/               <- engine support files
    vendor/librw/            <- patched rendering library
```

The pinned engine is `hottabxp/re3` commit `a16fcd8d6a79e433c1c6e73d540f1bbe27e14164`; librw is `18532c2e13efbc1aa43f0b00b4459831f9414de0`. This is the Vice City branch of the re3/reVC engine family, with Metal and native mod code ported from RegTA Upstate. Do not apply this patch to an arbitrary GTA III RegTA checkout or copy the GTA III executable into Vice City.

## 3. Copy your Vice City data and engine support files

Set these paths for your machine. **Replace `VC_DATA_SOURCE` with the folder that actually contains your Vice City `data` and `models` directories.** The example destination is a new folder, separate from your original game:

```sh
REVC_KIT="$HOME/Documents/Code/revc-metal"
VC_DATA_SOURCE="/path/to/your/original/Vice City"
VC_GAME_DIR="$HOME/Games/ViceCityMetal"
```

Check the source data before copying:

```sh
test -f "$VC_DATA_SOURCE/data/gta_vc.dat"
test -f "$VC_DATA_SOURCE/models/gta3.img"
test -f "$REVC_KIT/source/build-metal/src/reVC"
```

Each check should succeed. Stop if a check reports a missing file; correct the path first. `gta3.img` is also the name of Vice City's model archive, so that filename alone does not identify GTA III data.

Create the destination and copy the complete game directory. Then overlay the engine's own support files, including its `neo` configuration/textures and controller database:

```sh
mkdir -p "$VC_GAME_DIR"
rsync -a "$VC_DATA_SOURCE/" "$VC_GAME_DIR/"
rsync -a "$REVC_KIT/source/gamefiles/" "$VC_GAME_DIR/"
```

Do this with the native game stopped. The support-file overlay can replace files in the destination; start with a separate game copy and back up an existing modded destination before updating it. Windows EXE/DLL/ASI files may be present in your copied data directory, but the native engine does not execute Windows ASI plug-ins. Its supported mod features are native ports.

## 4. Install and sign the native executable

Make sure no native Vice City process is running:

```sh
pgrep -x reVC
pgrep -x reVC_metal
```

Both commands must print nothing. Then install:

```sh
cp "$REVC_KIT/source/build-metal/src/reVC" "$VC_GAME_DIR/reVC_metal"
codesign --force --sign - "$VC_GAME_DIR/reVC_metal"
codesign --verify --strict "$VC_GAME_DIR/reVC_metal"
```

The resulting folder should contain the executable beside the game directories:

```text
ViceCityMetal/
  reVC_metal
  audio/
  anim/
  data/gta_vc.dat
  models/gta3.img
  TEXT/
  neo/
  gamecontrollerdb.txt
```

Directory capitalization may follow your original installation. Keep all related archive/index files from the game copy together.

## 5. Launch from the game folder

```sh
cd "$VC_GAME_DIR"
./reVC_metal
```

The working directory must be the game folder so the engine can find its data. Choose New Game for story mode or Start Free Roam for the road selector. F7 opens the trainer; some Apple keyboards require Fn-F7. Graphics settings are under Options → Graphics → Advanced graphics. Settings are stored in `reVC.ini` in the runtime directory.

If you want a double-click launcher, create `Launch Vice City Metal.command` in the game folder with:

```sh
#!/bin/zsh
cd -- "${0:A:h}"
exec ./reVC_metal
```

Make that launcher executable:

```sh
chmod +x "$VC_GAME_DIR/Launch Vice City Metal.command"
```

## 6. Optional converted vehicles

Build and launch the stock-data setup before adding packs. The separate [IV-to-VC converter](https://github.com/mindingulove/iv-vc-car-converter) documents its dependencies and native validation requirements. Select this `VC_GAME_DIR` as its destination; it finds the `modloader` directory. Use Vice City-compatible packs and keep the authors' permissions/credits.

The converter requires a runtime capability marker matching its features. A manually copied executable alone does not create `NATIVE_CAR_ADDONS.json`; follow the converter's runtime setup/validation requirements before installing add-ons. An old marker from another build is not evidence that a new executable supports a feature. Converted lamp-lens breakage also requires regenerated models, not only an updated executable.

## 7. Updates and troubleshooting

- Close the game, back up the existing executable and modified runtime files, build the new source, then copy/sign the executable again. A running process retains the old executable until restarted.
- `build.sh` applies patches only when `source/` does not exist. To consume an updated patch, use a fresh kit checkout/source directory; an existing source directory is not automatically repatched. Keep your previous source/build as a backup.
- If the build cannot find OpenAL, use Homebrew's `openal-soft`; `build.sh` supplies its paths. The system OpenAL framework is not the intended build dependency.
- Missing `data/gta_vc.dat`, archive or texture errors usually require checking the working directory and completeness of the game/support-file copy.
- Do not copy GTA III/Upstate map or mission data into this runtime. The original PC Vice City data and the patched Vice City engine must match.
- M1 supports native 2x/4x MSAA. 8x/16x requests fall back to the supported hardware level and are labelled accordingly.
- In-game glass appearance, wet-road ghosting, demanding-scene performance and the long-running MetalFX/ANE abort remain under investigation. Successful building/signing is not a gameplay compatibility or FPS guarantee.

No game assets or converted vehicle packs are distributed by this build kit. Upstream engine and librw licenses/credits still apply.
