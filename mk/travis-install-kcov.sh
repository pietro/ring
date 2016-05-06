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
set -ex


# kcov 26 or newer is needed when getting coverage information for Rust.
# kcov 31 is needed so `kcov --version` doesn't exit with status 1.
KCOV_VERSION=${KCOV_VERSION:-31}

curl -L https://github.com/SimonKagstrom/kcov/archive/v$KCOV_VERSION.tar.gz | tar -zxf -

pushd kcov-$KCOV_VERSION

mkdir build

pushd build

export CC=$CC_X
export CXX=$CXX_X
export TARGET=$TARGET_X

# set PKG_CONFIG_PATH and compiler flags to cross compile kcov to $TARGET_X
case $TARGET_X in
aarch64-unknown-linux-gnu)
  export PKG_CONFIG_PATH="/usr/lib/aarch64-linux-gnu/pkgconfig"
  ;;
arm-unknown-linux-gnueabi)
  export PKG_CONFIG_PATH="/usr/lib/arm--linux-gnueabi/pkgconfig"
  ;;
i686-unknown-linux-gnu)
  export PKG_CONFIG_PATH="/usr/lib/i386-linux-gnu/pkgconfig"
  export CFLAGS="-m32"
  export CXXFLAGS="-m32"
  ;;
*)
  ;;
esac

cmake -DCMAKE_INSTALL_PREFIX:PATH="${HOME}/kcov" ..
make
make install

$HOME/kcov/bin/kcov --version

popd
popd
