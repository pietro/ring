#!/usr/bin/env bash
#
# Copyright 2015 Brian Smith.
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND AND THE AUTHORS DISCLAIM ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY
# SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION
# OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN
# CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

set -eux -o pipefail
IFS=$'\n\t'

printenv

if [[ ! "$TARGET_X" =~ "x86_64-" ]]; then
   sh ~/rust-installer/rustup.sh --add-target=$TARGET_X \
     --disable-sudo -y \
     --prefix=`rustc --print sysroot`

  # By default cargo/rustc seems to use cc for linking, We installed the
  # multilib support that corresponds to $CC_X and $CXX_X but unless cc happens
  # to match #CC_X, that's not the right version. The symptom is a linker error
  # where it fails to find -lgcc_s.
  mkdir .cargo
  echo "[target.$TARGET_X]" > .cargo/config
  echo "linker= \"$CC_X\"" >> .cargo/config
  cat .cargo/config
fi

# If we're testing with a docker image, then run tests entirely within that
# image. Note that this is using the same rustc installation that travis has
# (sharing it via `-v`) and otherwise the tests run entirely within the
# container.
#
# For the docker build we mount the entire current directory at /checkout, set
# up some environment variables to let it run, and then run the standard run.sh
# script.
if [ "${DOCKER-}" != "" ]; then
  args=""

pwd
ls -l

  exec docker run \
    --entrypoint bash \
    -v `rustc --print sysroot`:/usr/local:ro \
    -v `pwd`:/checkout:rw \
    -e LD_LIBRARY_PATH=/usr/local/lib \
    -e CARGO_TARGET_DIR=/tmp \
    $args \
    -w /checkout \
    -it $DOCKER \
    mk/run.sh $TARGET_X
fi

echo end of mk/travis.sh
