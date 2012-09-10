#!/bin/sh

. ./bin/build-config.sh

FRAMEWORK_NAME=mobiruby
FRAMEWORK_VERSION=A
FRAMEWORK_CURRENT_VERSION=1
FRAMEWORK_COMPATIBILITY_VERSION=1

PROJECT_DIR=`pwd`
MRBC=${PROJECT_DIR}/bin/mrbc

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

    export CC="${platform}"/Developer/usr/bin/gcc
    export CFLAGS="-g -O3 \
    -F ${PROJECT_DIR}/Frameworks -framework mruby \
    -framework Foundation \
    -arch ${arch} \
    -isysroot ${sdk} \
    -D__IPHONE_OS_VERSION_MIN_REQUIRED=50100 \
    -gdwarf-2 \
    -miphoneos-version-min=${MIN_IOS_VERSION}"
    mkdir -p "build/${builddir}"
    make clean
    make CC="${CC}" LL="${CC}" CFLAGS="${CFLAGS} -I${PROJECT_DIR}/modules/mruby/include" MRBC="${mrbc}" TARGET="build/${builddir}/libmobiruby.a" 
}
build_target armv6 arm-apple-darwin10 armv6-ios "${PLATFORM_IOS}" "${PLATFORM_IOS}/Developer/SDKs/iPhoneOS${SDK_IOS_VERSION}.sdk/"
build_target armv7 arm-apple-darwin10 armv7-ios "${PLATFORM_IOS}" "${PLATFORM_IOS}/Developer/SDKs/iPhoneOS${SDK_IOS_VERSION}.sdk/"
build_target i386 i386-apple-darwin10 i386-ios-sim "${PLATFORM_IOS_SIM}" "${PLATFORM_IOS_SIM}/Developer/SDKs/iPhoneSimulator${SDK_IOS_VERSION}.sdk/"


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
-arch armv6 build/armv6-ios/libmobiruby.a \
-arch armv7 build/armv7-ios/libmobiruby.a \
-arch i386 build/i386-ios-sim/libmobiruby.a \
-o "${FRAMEWORK_DIR}/Versions/Current/${FRAMEWORK_NAME}"

# Now copy the final assets over: your library
# header files and the plist file
echo "Framework: Copying headers into current version..."
cp modules/libffi-iOS/ios/include/*.h ${FRAMEWORK_DIR}/Headers/
cp modules/mruby-cfunc/include/*.h ${FRAMEWORK_DIR}/Headers/
cp modules/mruby-cocoa/include/*.h ${FRAMEWORK_DIR}/Headers/
find ${FRAMEWORK_DIR}/Headers/ -regex ".*h$" -type f -print0 | \
  xargs -0 sed -i .orig \
  -e "s/include \"mruby\.h\"/include \"mruby\/mruby\.h\"/;"
rm ${FRAMEWORK_DIR}/Headers/*.orig

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
    <string>org.mobiruby.mobiruby</string>\
    <key>CFBundleInfoDictionaryVersion</key>\
    <string>6.0</string>\
    <key>CFBundlePackageType</key>\
    <string>FMWK</string>\
    <key>CFBundleSignature</key>\
    <string>????</string>\
    <key>CFBundleVersion</key>\
    <string>1.0</string>\
    <key>NSHumanReadableCopyright</key>
    <string>Copyright MobiRuby developers.</string>
    <key>NSPrincipalClass</key>
    <string></string>

</dict>" >  ${FRAMEWORK_DIR}/Resources/Info.plist
