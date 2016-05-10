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
  ./mk/travis-install-rust-std.sh

  # By default cargo/rustc seems to use cc for linking, We installed the
  # multilib support that corresponds to $CC_X and $CXX_X but unless cc happens
  # to match #CC_X, that's not the right version. The symptom is a linker error
  # where it fails to find -lgcc_s.
  mkdir .cargo
  echo "[target.$TARGET_X]" > .cargo/config
  echo "linker= \"$CC_X\"" >> .cargo/config
  cat .cargo/config
fi

$CC_X --version
$CXX_X --version
make --version

cargo version
rustc --version

if [[ "$MODE_X" == "RELWITHDEBINFO" ]]; then mode=--release; fi

case $TARGET_X in
aarch64-unknown-linux-gnu)
  export QEMU_LD_PREFIX=/usr/aarch64-linux-gnu
  ;;
arm-unknown-linux-gnueabi)
  export QEMU_LD_PREFIX=/usr/arm-linux-gnueabi
    ;;
*)
  ;;
esac

if [[ "$KCOV" == "1" ]]; then
  # kcov reports coverage as a percentage of code *linked into the executable*
  # (more accurately, code that has debug info linked into the executable), not
  # as a percentage of source code. Thus, any code that gets discarded by the
  # linker due to lack of usage isn't counted at all. Thus, we have to re-link
  # with "-C link-dead-code" to get accurate code coverage reports.
  # Alternatively, we could link pass "-C link-dead-code" in the "cargo test"
  # step above, but then "cargo test" we wouldn't be testing the configuration
  # we expect people to use in production.
  CC=$CC_X CXX=$CXX_X cargo clean
  CC=$CC_X CXX=$CXX_X RUSTFLAGS="-C link-dead-code" \
    cargo test --no-run -j2  ${mode-} --verbose --target=$TARGET_X
  mk/travis-install-kcov.sh
  ${HOME}/kcov/bin/kcov --verify \
                        --coveralls-id=$TRAVIS_JOB_ID \
                        --exclude-path=/usr/include \
                        --include-pattern="ring/crypto,ring/src" \
                        target/kcov \
                        target/$TARGET_X/debug/ring-*
fi

# Verify that `cargo build`, independent from `cargo test`, works; i.e. verify
# that non-test builds aren't trying to use test-only features. For platforms
# for which we don't run tests, this is the only place we even verify that the
# code builds.
CC=$CC_X CXX=$CXX_X cargo build -j2 ${mode-} --verbose --target=$TARGET_X

echo end of mk/travis.sh
