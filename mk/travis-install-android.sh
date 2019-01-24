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

ANDROID_SDK_VERSION=${ANDROID_SDK_VERSION:-24.4.1}
ANDROID_SDK_URL=https://dl.google.com/android/android-sdk_r${ANDROID_SDK_VERSION}-linux.tgz

ANDROID_NDK_VERSION=${ANDROID_NDK_VERSION:-17}
ANDROID_NDK_URL=https://dl.google.com/android/repository/android-ndk-r${ANDROID_NDK_VERSION}-linux-x86_64.zip

ANDROID_INSTALL_PREFIX="${HOME}/android"
ANDROID_SDK_INSTALL_DIR="${ANDROID_INSTALL_PREFIX}/android-sdk-linux"
ANDROID_NDK_INSTALL_DIR="${ANDROID_INSTALL_PREFIX}/${TARGET_X}${ANDROID_API_LEVEL}"

case $TARGET_X in
    aarch64-linux-android)
        SYS_TAG="arm64-v8a"
        NDK_ARCH=arm64
        ;;
    armv7-linux-androideabi)
        SYS_TAG="armeabi-v7a"
        NDK_ARCH=arm
        ;;
esac

if [[ ! -d $ANDROID_SDK_INSTALL_DIR ]]; then
  SDK_PACKAGES="tools,platform-tools"

  mkdir -p "${ANDROID_INSTALL_PREFIX}"
  pushd "${ANDROID_INSTALL_PREFIX}"

  curl ${ANDROID_SDK_URL} | tar -zxf -

  popd
fi

if [[ ! -d $ANDROID_SDK_INSTALL_DIR/platforms/android-$ANDROID_API_LEVEL ]]; then
    if [[ -z $SDK_PACKAGES ]]; then
        SDK_PACKAGES="android-$ANDROID_API_LEVEL"
    else
        SDK_PACKAGES="$SDK_PACKAGES,android-$ANDROID_API_LEVEL"
    fi
fi

if [[ ! -d $ANDROID_SDK_INSTALL_DIR/system-images/android-$ANDROID_API_LEVEL/default/$SYS_TAG ]]; then
    if [[ -z $SDK_PACKAGES ]]; then
        SDK_PACKAGES="sys-img-$SYS_TAG-android-$ANDROID_API_LEVEL"
    else
        SDK_PACKAGES="$SDK_PACKAGES,sys-img-$SYS_TAG-android-$ANDROID_API_LEVEL"
    fi
fi

if [[ ! -z $SDK_PACKAGES ]]; then

  expect -c "
set timeout 600;
spawn $ANDROID_SDK_INSTALL_DIR/tools/android update sdk -a --no-ui --filter $SDK_PACKAGES;
expect {
    \"Do you accept the license\" { exp_send \"y\r\" ; exp_continue }
    eof
}
"
fi

if [[ ! -f $ANDROID_NDK_INSTALL_DIR/bin/$CC_X ]];then
  mkdir -p "${ANDROID_INSTALL_PREFIX}/downloads"
  pushd "${ANDROID_INSTALL_PREFIX}/downloads"

  curl -O ${ANDROID_NDK_URL}
  unzip -q android-ndk-r${ANDROID_NDK_VERSION}-linux-x86_64.zip

  ./android-ndk-r${ANDROID_NDK_VERSION}/build/tools/make_standalone_toolchain.py \
		 --force \
		 --arch ${NDK_ARCH} \
		 --api ${ANDROID_API_LEVEL} \
		 --install-dir ${ANDROID_NDK_INSTALL_DIR}

  popd
  rm -rf "${ANDROID_INSTALL_PREFIX}/downloads"
fi

echo end of mk/travis-install-android
