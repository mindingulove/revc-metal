#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
command -v brew >/dev/null
brew install cmake glfw openal-soft mpg123 glslang spirv-cross
if [ ! -d source ]; then
 git clone --no-checkout https://github.com/hottabxp/re3.git source
 git -C source checkout --detach a16fcd8d6a79e433c1c6e73d540f1bbe27e14164
 git -C source apply --check ../revc-metal.patch
 git -C source apply ../revc-metal.patch
 git -C source submodule update --init vendor/librw
 git -C source/vendor/librw fetch origin 18532c2e13efbc1aa43f0b00b4459831f9414de0
 git -C source/vendor/librw checkout --detach 18532c2e13efbc1aa43f0b00b4459831f9414de0
 git -C source/vendor/librw apply --check ../../../librw-metal.patch
 git -C source/vendor/librw apply ../../../librw-metal.patch
fi
cmake -S source -B source/build-metal -DLIBRW_METALGL=ON -DLIBRW_PLATFORM=GL3 -DLIBRW_GL3_GFXLIB=GLFW -DREVC_AUDIO=OAL -DOPENAL_INCLUDE_DIR="$(brew --prefix openal-soft)/include" -DOPENAL_LIBRARY="$(brew --prefix openal-soft)/lib/libopenal.dylib"
cmake --build source/build-metal -j 8
