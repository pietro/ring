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

ANDROID_SDK_TOOLS_VERSION=${ANDROID_SDK_TOOLS_VERSION:-3859397}
ANDROID_SDK_TOOLS_URL=https://dl.google.com/android/repository/sdk-tools-linux-${ANDROID_SDK_TOOLS_VERSION}.zip

ANDROID_NDK_VERSION=${ANDROID_NDK_VERSION:-17}
ANDROID_NDK_URL=https://dl.google.com/android/repository/android-ndk-r${ANDROID_NDK_VERSION}-linux-x86_64.zip

ANDROID_INSTALL_PREFIX="${HOME}/android"
ANDROID_SDK_INSTALL_DIR="${ANDROID_INSTALL_PREFIX}/sdk"
ANDROID_NDK_INSTALL_DIR="${ANDROID_INSTALL_PREFIX}/android-18-arm-linux-androideabi-4.8"

mkdir -p "${ANDROID_SDK_INSTALL_DIR}"
pushd "${ANDROID_INSTALL_PREFIX}"

if [[ ! -f $ANDROID_SDK_INSTALL_DIR/tools/bin/sdkmanager ]];then
  mkdir -p "${ANDROID_INSTALL_PREFIX}/downloads"
  pushd "${ANDROID_INSTALL_PREFIX}/downloads"

  curl -O ${ANDROID_SDK_TOOLS_URL}
  unzip -q sdk-tools-linux-${ANDROID_SDK_TOOLS_VERSION}.zip -d ${ANDROID_SDK_INSTALL_DIR}

  popd

  yes | ./sdk/tools/bin/sdkmanager --licenses > /dev/null
  ./sdk/tools/bin/sdkmanager platform-tools emulator "platforms;android-18" "system-images;android-18;default;armeabi-v7a"
fi

yes | ./sdk/tools/bin/sdkmanager --licenses > /dev/null
./sdk/tools/bin/sdkmanager --update

popd

if [[ ! -d $ANDROID_NDK_INSTALL_DIR/sysroot/usr/include/arm-linux-androideabi ]];then
  mkdir -p "${ANDROID_INSTALL_PREFIX}/downloads"
  pushd "${ANDROID_INSTALL_PREFIX}/downloads"

  curl -O ${ANDROID_NDK_URL}
  unzip -q android-ndk-r${ANDROID_NDK_VERSION}-linux-x86_64.zip

  ./android-ndk-r${ANDROID_NDK_VERSION}/build/tools/make_standalone_toolchain.py \
		 --force \
		 --arch arm \
		 --api 18 \
		 --install-dir ${ANDROID_NDK_INSTALL_DIR}

  popd
fi

rm -rf "${ANDROID_INSTALL_PREFIX}/downloads"

echo end of mk/travis-install-android
