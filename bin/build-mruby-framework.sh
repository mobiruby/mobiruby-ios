#!/bin/sh

. ./bin/build-config.sh

FRAMEWORK_NAME=mruby
FRAMEWORK_VERSION=A
FRAMEWORK_CURRENT_VERSION=1
FRAMEWORK_COMPATIBILITY_VERSION=1

MRBC=`pwd`/bin/mrbc

build_mrbc () {
    pushd modules/mruby
    make clean
    make
    cp bin/mrbc ${MRBC}
    popd
}
[ -x "${MRBC}" ] || build_mrbc

build_target () {
    local arch=$1
    local triple=$2
    local builddir=$3
    local platform=$4
    local sdk=$5

    pushd modules/mruby
    mkdir -p "${builddir}"
    make clean
    export CC="${platform}"/usr/bin/gcc
    export CFLAGS="-arch ${arch} -isysroot ${sdk} -D ALLOC_PADDING=8 -miphoneos-version-min=${MIN_IOS_VERSION} -g -O3"
    make CC="${CC}" CFLAGS="${CFLAGS}" -C src
    make CC="${CC}" CFLAGS="${CFLAGS}" MRBC="${MRBC}" CAT="/bin/cat" CP="/bin/cp" AR="/usr/bin/ar" -C mrblib
    cp lib/libmruby.a "${builddir}"/
    popd
}

build_target armv6 arm-apple-darwin10 armv6-ios "${GCC_PLATFORM_IOS}" "${PLATFORM_IOS}/Developer/SDKs/iPhoneOS${SDK_IOS_VERSION}.sdk/"
build_target armv7 arm-apple-darwin10 armv7-ios "${GCC_PLATFORM_IOS}" "${PLATFORM_IOS}/Developer/SDKs/iPhoneOS${SDK_IOS_VERSION}.sdk/"
build_target i386 i386-apple-darwin10 i386-ios-sim "${GCC_PLATFORM_IOS_SIM}" "${PLATFORM_IOS_SIM}/Developer/SDKs/iPhoneSimulator${SDK_IOS_VERSION}.sdk/"


# Where we'll put the build framework.
# The script presumes we're in the project root
# directory. Xcode builds in "build" by default
FRAMEWORK_BUILD_PATH="Frameworks"

# This is the full name of the framework we'll
# build
FRAMEWORK_DIR=${FRAMEWORK_BUILD_PATH}/${FRAMEWORK_NAME}.framework

# Clean any existing framework that might be there
# already
echo "Framework: Cleaning framework..."
[ -d "${FRAMEWORK_DIR}" ] && rm -rf "${FRAMEWORK_DIR}"

# Build the canonical Framework bundle directory
# structure
echo "Framework: Setting up directories..."
mkdir -p ${FRAMEWORK_DIR}
mkdir -p ${FRAMEWORK_DIR}/Versions
mkdir -p ${FRAMEWORK_DIR}/Versions/${FRAMEWORK_VERSION}
mkdir -p ${FRAMEWORK_DIR}/Versions/${FRAMEWORK_VERSION}/Resources
mkdir -p ${FRAMEWORK_DIR}/Versions/${FRAMEWORK_VERSION}/Headers

echo "Framework: Creating symlinks..."
ln -s ${FRAMEWORK_VERSION} ${FRAMEWORK_DIR}/Versions/Current
ln -s Versions/Current/Headers ${FRAMEWORK_DIR}/Headers
ln -s Versions/Current/Resources ${FRAMEWORK_DIR}/Resources
ln -s Versions/Current/${FRAMEWORK_NAME} ${FRAMEWORK_DIR}/${FRAMEWORK_NAME}

# The trick for creating a fully usable library is
# to use lipo to glue the different library
# versions together into one file. When an
# application is linked to this library, the
# linker will extract the appropriate platform
# version and use that.
# The library file is given the same name as the
# framework with no .a extension.
echo "Framework: Creating library..."
lipo \
-create \
-arch armv6 modules/mruby/armv6-ios/libmruby.a \
-arch armv7 modules/mruby/armv7-ios/libmruby.a \
-arch i386 modules/mruby/i386-ios-sim/libmruby.a \
-o "${FRAMEWORK_DIR}/Versions/Current/${FRAMEWORK_NAME}"


# Now copy the final assets over: your library
# header files and the plist file
echo "Framework: Copying headers into current version..."
cp modules/mruby/include/*.h ${FRAMEWORK_DIR}/Headers/
cp modules/mruby/include/mruby/*.h ${FRAMEWORK_DIR}/Headers/
find ${FRAMEWORK_DIR}/Headers/ -regex ".*h$" -type f -print0 | \
  xargs -0 sed -i .orig \
  -e "s/include \"/include \"mruby\//;s/include \"mruby\/mruby/include \"mruby/"
rm ${FRAMEWORK_DIR}/Headers/*.orig
cp ${MRBC} ${FRAMEWORK_DIR}/Resources/

echo "\
<?xml version="1.0" encoding="UTF-8"?>\
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\
<plist version="1.0">\
<dict>\
    <key>CFBundleDevelopmentRegion</key>\
    <string>English</string>\
    <key>CFBundleExecutable</key>\
    <string>mruby</string>\
    <key>CFBundleIdentifier</key>\
    <string>org.mobiruby.mruby</string>\
    <key>CFBundleInfoDictionaryVersion</key>\
    <string>6.0</string>\
    <key>CFBundlePackageType</key>\
    <string>FMWK</string>\
    <key>CFBundleSignature</key>\
    <string>????</string>\
    <key>CFBundleVersion</key>\
    <string>1.0</string>\
    <key>NSHumanReadableCopyright</key>
    <string>Copyright mruby developers.</string>
    <key>NSPrincipalClass</key>
    <string></string>

</dict>" >  ${FRAMEWORK_DIR}/Resources/Info.plist
