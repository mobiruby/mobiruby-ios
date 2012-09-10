#!/bin/sh

. ./bin/build-config.sh
OUTPUT_DIR=`pwd`/modules/libffi

mkdir -p tmp
cd tmp
git clone https://github.com/atgreen/libffi.git
cd libffi
sed -i -e "s/align 0/align 4/g" src/arm/sysv.S

build_target () {
    local arch=$1
    local triple=$2
    local builddir=$3
    local platform=$4
    local sdk=$5

    mkdir -p "${builddir}"
    pushd "${builddir}"
    export CC="${platform}"/Developer/usr/bin/gcc
    export CFLAGS="-g -Os \
    -arch ${arch} \
    -isysroot ${sdk} \
    -D__IPHONE_OS_VERSION_MIN_REQUIRED=50100 \
    -gdwarf-2  \
    -miphoneos-version-min=${MIN_IOS_VERSION}"
    ../configure --host=${triple} && make
    popd
}
build_target armv6 arm-apple-darwin10 armv6-ios "${PLATFORM_IOS}" "${PLATFORM_IOS}/Developer/SDKs/iPhoneOS${SDK_IOS_VERSION}.sdk/"
build_target armv7 arm-apple-darwin10 armv7-ios "${PLATFORM_IOS}" "${PLATFORM_IOS}/Developer/SDKs/iPhoneOS${SDK_IOS_VERSION}.sdk/"
build_target i386 i386-apple-darwin10 i386-ios-sim "${PLATFORM_IOS_SIM}" "${PLATFORM_IOS_SIM}/Developer/SDKs/iPhoneSimulator${SDK_IOS_VERSION}.sdk/"


# Create universal output directories
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}/include"
mkdir -p "${OUTPUT_DIR}/include/armv6"
mkdir -p "${OUTPUT_DIR}/include/armv7"
mkdir -p "${OUTPUT_DIR}/include/i386"

# Create the universal binary
lipo -create armv6-ios/.libs/libffi.a armv7-ios/.libs/libffi.a i386-ios-sim/.libs/libffi.a -output "${OUTPUT_DIR}/libffi.a"

# Copy in the headers
copy_headers () {
    local src=$1
    local dest=$2

    # Fix non-relative header reference
    sed 's/<ffitarget.h>/"ffitarget.h"/' < "${src}/include/ffi.h" > "${dest}/ffi.h"
    cp "${src}/include/ffitarget.h" "${dest}"
}

copy_headers armv6-ios "${OUTPUT_DIR}/include/armv6"
copy_headers armv7-ios "${OUTPUT_DIR}/include/armv7"
copy_headers i386-ios-sim "${OUTPUT_DIR}/include/i386"

# Create top-level header
(
cat << EOF
#ifdef __arm__
  #include <arm/arch.h>
  #ifdef _ARM_ARCH_6
    #include "include/armv6/ffi.h"
  #elif _ARM_ARCH_7
    #include "include/armv7/ffi.h"
  #endif
#elif defined(__i386__)
  #include "include/i386/ffi.h"
#endif
EOF
) > "${OUTPUT_DIR}/ffi.h"


