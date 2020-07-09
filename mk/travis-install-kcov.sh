#!/usr/bin/env bash
#
# Copyright (c) 2016 Pietro Monteiro
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
set -eux -o pipefail


# kcov 26 or newer is needed when getting coverage information for Rust.
# kcov 31 is needed so `kcov --version` doesn't exit with status 1.
# kcov 32 is required for macos
# kcov 38 is required for Aarch64 (ARM64)
KCOV_VERSION=${KCOV_VERSION:-38}

KCOV_INSTALL_PREFIX="${HOME}/kcov"

KCOV_BIN="${KCOV_INSTALL_PREFIX}/bin/kcov"

BUILD_HOST=$(uname -m)

# Check if kcov has been cached on travis.
if [[ -x "${KCOV_BIN}" ]]; then
  KCOV_INSTALLED_VERSION=$(${KCOV_BIN} --version)
  # Exit if we don't need to upgrade kcov.
  if [[ "$KCOV_INSTALLED_VERSION" == "kcov $KCOV_VERSION" ]]; then
    echo "Using cached kcov version: ${KCOV_VERSION}"
    exit 0
  else
    rm -rf "$KCOV_INSTALL_PREFIX"
  fi
fi

curl -L "https://github.com/SimonKagstrom/kcov/archive/v${KCOV_VERSION}.tar.gz" | tar -zxf -

pushd "kcov-${KCOV_VERSION}"

mkdir build
pushd build

if [[ ! "$TARGET_X" =~ ^"${BUILD_HOST}" ]]; then
  if [[  "$TARGET_X" == "i686-unknown-linux-gnu" ]]; then
    # set the correct PKG_CONFIG_PATH so the kcov build system uses the 32 bit libraries we installed.
    # otherwise kcov will be linked with 64 bit libraries and won't work with 32 bit executables.
    export PKG_CONFIG_PATH="/usr/lib/i386-linux-gnu/pkgconfig"
    export CFLAGS="-m32"
    export CXXFLAGS="-m32"
  else
    export PKG_CONFIG_PATH="/usr/lib/${TARGET_X}/pkgconfig"
  fi
  export TARGET="${TARGET_X}"
fi

cmake -DCMAKE_INSTALL_PREFIX:PATH="${KCOV_INSTALL_PREFIX}" ..

make
make install

"${KCOV_BIN}" --version

popd
popd
