#!/bin/sh

. ./bin/build-config.sh
INCLUDE_DIR=`pwd`/include
LIB_DIR=`pwd`/lib
build_target () {
    local arch=$1
    local platform=$2
    local sdk=$3

    export CC="${platform}"/Developer/usr/bin/gcc
    export CFLAGS="-g -Os \
    -arch ${arch} \
    -isysroot ${sdk} \
    -D__IPHONE_OS_VERSION_MIN_REQUIRED=50100 \
    -gdwarf-2  \
    -miphoneos-version-min=${MIN_IOS_VERSION}"
    make clean all
    cp libuv.a "libuv-${arch}.a"
}

cd submodules/libuv

# remove process title property
echo "int uv__set_process_title(const char* title) { return -1; }" > "src/unix/darwin-proctitle.m"

build_target armv7 "${PLATFORM_IOS}" "${PLATFORM_IOS}/Developer/SDKs/iPhoneOS${SDK_IOS_VERSION}.sdk/"
build_target armv7s "${PLATFORM_IOS}" "${PLATFORM_IOS}/Developer/SDKs/iPhoneOS${SDK_IOS_VERSION}.sdk/"
build_target i386 "${PLATFORM_IOS_SIM}" "${PLATFORM_IOS_SIM}/Developer/SDKs/iPhoneSimulator${SDK_IOS_VERSION}.sdk/"


# Create universal output directories
mkdir -p "${INCLUDE_DIR}"
mkdir -p "${LIB_DIR}"

# Create the universal binary
lipo -create libuv-armv7s.a libuv-armv7.a libuv-i386.a -output "${LIB_DIR}/libuv.a"
cp -r include/* "${INCLUDE_DIR}/"
