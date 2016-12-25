#!/bin/bash

###############################################################################
#
# This script will build FFMPEG for android.
#
# Prerequisits:
#   - None
#
# Build steps:
#   - Checkout FFMPEG Source and lock to 3.2 Branch (latest version at time
#     of script creation)
#   - Patch the FFMPEG configure script to fix missing support for shared
#     library versioning on android.
#   - Configure FFMPEG
#   - Build FFMPEG
#
###############################################################################
SCRIPT=$(cd "$(dirname "$0")"; pwd)/$(basename $0)
BASE=$(dirname $SCRIPT)
###############################################################################
#
# Argument parsing.
#  Allow some components to be overwritten by command line arguments.
#
###############################################################################
if [ -z $HOST_ARCH]; then
  HOST_ARCH=$(uname -m)
fi

if [ -z $PLATFORM ]; then
  PLATFORM=9
fi

if [ -z $MAKE_OPTS ]; then
  MAKE_OPTS="-j4"
fi

if [ -z $ALL ]; then
  ALL="NO"
fi

function usage
{
  echo "$0 [-a <ndk>] [-h <host arch>] [-m <make opts>] [-p <android platform>] [-v y]"
  echo -e "\tdefaults:"
  echo -e "\t-h\tHOST_ARCH=$HOST_ARCH"
  echo -e "\t-p\tPLATFORM=$PLATFORM"
  echo -e "\t-m\tMAKE_OPTS=$MAKE_OPTS"
  echo -e "\t-v\t64-BIT Arches=$ALL (Platform 21+)"
  echo -e "\t-a\tANDROID_NDK must be set manually."
  echo ""
  echo -e "\tAll arguments can also be set as environment variables."
  exit -3
}

while getopts "a:h:m:p:v" opt; do
  case $opt in
    a)
      ANDROID_NDK=$OPTARG
      ;;
    h)
      HOST_ARCH=$OPTARG
      ;;
    m)
      MAKE_OPTS=$OPTARG
      ;;
    p)
      PLATFORM=$OPTARG
      ;;
    v)
      ALL="YES"
      ;;
    \?)
      echo "Invalid option $OPTARG" >&2
      usage
      ;;
  esac
done

if [ -z $HOST_ARCH ]; then
  HOST_ARCH=$(uname -m)
fi

if [ -z $PLATFORM ]; then
  PLATFORM=9
fi

if [ -z $MAKE_OPTS ]; then
  MAKE_OPTS="-j4"
fi

if [ -z $ANDROID_NDK ]; then
  echo "ANDROID_NDK not set. Set it to the directory of your NDK installation."
  exit -1
fi
if [ ! -d $BASE/FFmpeg ]; then
  echo "Please copy or check out FFMPEG source to folder: FFmpeg!"
  exit -2
fi

echo "Refreshing FFMpeg 3.2 Library"
echo "-----------------------------------------------"
cd $BASE/FFmpeg
git checkout release/3.2
cd ..
git submodule update --init
git submodule update --remote

echo "-----------------------------------------------"
echo "Building with:"
echo "-----------------------------------------------"
echo "HOST_ARCH=$HOST_ARCH"
echo "PLATFORM=$PLATFORM"
echo "MAKE_OPTS=$MAKE_OPTS"
echo "ANDROID_NDK=$ANDROID_NDK"
echo "64-BIT ARCHES: $ALL"
echo "-----------------------------------------------"

cd $BASE/FFmpeg

# Save original configuration file
# or restore original before applying patches.
if [ ! -f configure.bak ]; then
  echo "Saving original configure file to configure.bak"
  cp configure configure.bak
else
  echo "Restoring original configure file from configure.bak"
  cp configure.bak configure
fi

patch -p1 < $BASE/patches/config.patch

if [ ! -f library.mak.bak ]; then
  echo "Saving original library.mak file to library.mak.bak"
  cp library.mak library.mak.bak
else
  echo "Restoring original library.mak file from library.mak.bak"
  cp library.mak.bak library.mak
fi

patch -p1 < $BASE/patches/library.mak.patch

# Remove old build and installation files.
if [ -d $BASE/install ]; then
  rm -rf $BASE/install
fi
if [ -d $BASE/build ]; then
  rm -rf $BASE/build
fi

###############################################################################
#
# build_one ... builds FFMPEG with provided arguments.
#
# Calling convention:
#
# build_one <PREFIX> <CROSS_PREFIX> <ARCH> <SYSROOT> <CFLAGS> <LDFLAGS> <EXTRA>
#
#  PREFIX       ... Installation directory
#  CROSS_PREFIX ... Full path with toolchain prefix
#  ARCH         ... Architecture to build for (arm, x86, mips)
#  SYSROOT      ... Android platform to build for, full path.
#  CFLAGS       ... Additional CFLAGS for building.
#  LDFLAGS      ... Additional LDFLAGS for linking
#  EXTRA        ... Any additional configuration flags, e.g. --cpu=XXX
#
###############################################################################
function build_one
{
  mkdir -p $1
  cd $1

  $BASE/FFmpeg/configure \
      --prefix=$2 \
      --enable-shared \
      --disable-static \
      --disable-doc \
      --disable-ffmpeg \
      --disable-ffplay \
      --disable-ffprobe \
      --disable-ffserver \
      --disable-avdevice \
      --disable-doc \
      --enable-symver \
      --cross-prefix=$3 \
      --target-os=linux \
      --enable-pic \
      --arch=$4 \
      --enable-cross-compile \
      --sysroot=$5 \
      --extra-cflags="-Os $6" \
      --extra-ldflags="$7" \
      $8 > ../install.log 2>&1

  make clean > ../install.log 2>&1
  make $MAKE_OPTS > ../install.log 2>&1
  make install > ../install.log 2>&1
}

NDK=$ANDROID_NDK
touch ../install.log


###############################################################################
#
# ARM build configuration
#
###############################################################################
echo "Building: ARM"
echo "Building: ARM" > install.log
PREFIX=$BASE/install/armeabi
BUILD_ROOT=$BASE/build/armeabi
SYSROOT=$NDK/platforms/android-$PLATFORM/arch-arm/
TOOLCHAIN=$NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/darwin-$HOST_ARCH
CROSS_PREFIX=$TOOLCHAIN/bin/arm-linux-androideabi-
ARCH=arm
E_CFLAGS=
E_LDFLAGS=
EXTRA=

build_one "$BUILD_ROOT" "$PREFIX" "$CROSS_PREFIX" "$ARCH" "$SYSROOT" \
    "$E_CFLAGS" "$E_LDFLAGS" "$EXTRA"
exit 1
###############################################################################
#
# ARM-v7a build configuration
#
###############################################################################
PREFIX=$BASE/install/armeabi-v7a
BUILD_ROOT=$BASE/build/armeabi-v7a
SYSROOT=$NDK/platforms/android-$PLATFORM/arch-arm/
TOOLCHAIN=$NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/darwin-$HOST_ARCH
CROSS_PREFIX=$TOOLCHAIN/bin/arm-linux-androideabi-
ARCH=arm
E_CFLAGS="-march=armv7-a -mfloat-abi=softfp"
E_LDFLAGS=
EXTRA=

build_one "$BUILD_ROOT" "$PREFIX" "$CROSS_PREFIX" "$ARCH" "$SYSROOT" \
    "$E_CFLAGS" "$E_LDFLAGS" "$EXTRA"

###############################################################################
#
# x86 build configuration
#
###############################################################################
PREFIX=$BASE/install/x86
BUILD_ROOT=$BASE/build/x86
SYSROOT=$NDK/platforms/android-$PLATFORM/arch-x86/
TOOLCHAIN=$NDK/toolchains/x86-4.9/prebuilt/darwin-$HOST_ARCH
CROSS_PREFIX=$TOOLCHAIN/bin/i686-linux-android-
ARCH=x86
E_CFLAGS=
E_LDFLAGS=
EXTRA="--disable-asm"

build_one "$BUILD_ROOT" "$PREFIX" "$CROSS_PREFIX" "$ARCH" "$SYSROOT" \
    "$E_CFLAGS" "$E_LDFLAGS" "$EXTRA"

###############################################################################
#
# MIPS build configuration
#
###############################################################################
PREFIX=$BASE/install/mips
BUILD_ROOT=$BASE/build/mips
SYSROOT=$NDK/platforms/android-$PLATFORM/arch-mips/
TOOLCHAIN=$NDK/toolchains/mipsel-linux-android-4.9/prebuilt/darwin-$HOST_ARCH
CROSS_PREFIX=$TOOLCHAIN/bin/mipsel-linux-android-
ARCH=mips
E_CFLAGS="-fno-strict-aliasing -fmessage-length=0 -fno-inline-functions-called-once -frerun-cse-after-loop -frename-registers"
E_LDFLAGS=
EXTRA="--cpu=mips32r2 \
--enable-runtime-cpudetect \
--enable-yasm \
--disable-mipsfpu \
--disable-mipsdspr2"

build_one "$BUILD_ROOT" "$PREFIX" "$CROSS_PREFIX" "$ARCH" "$SYSROOT" \
    "$E_CFLAGS" "$E_LDFLAGS" "$EXTRA"

###############################################################################
#
# ARM64-v8a build configuration
#
###############################################################################
PREFIX=$BASE/install/arm64-v8a
BUILD_ROOT=$BASE/build/arm64-v8a
SYSROOT=$NDK/platforms/android-$PLATFORM/arch-arm64/
TOOLCHAIN=$NDK/toolchains/aarch64-linux-android-4.9/prebuilt/darwin-$HOST_ARCH
CROSS_PREFIX=$TOOLCHAIN/bin/aarch64-linux-android-
ARCH=arm64
E_CFLAGS=
E_LDFLAGS=
EXTRA=

if [ "$ALL" == "YES" ]; then
build_one "$BUILD_ROOT" "$PREFIX" "$CROSS_PREFIX" "$ARCH" "$SYSROOT" \
"$E_CFLAGS" "$E_LDFLAGS" "$EXTRA"
fi

###############################################################################
#
# x86_64 build configuration
#
###############################################################################
PREFIX=$BASE/install/x86_64
BUILD_ROOT=$BASE/build/x86_64
SYSROOT=$NDK/platforms/android-$PLATFORM/arch-x86_64/
TOOLCHAIN=$NDK/toolchains/x86_64-4.9/prebuilt/darwin-$HOST_ARCH
CROSS_PREFIX=$TOOLCHAIN/bin/x86_64-linux-android-
ARCH=x86-64
E_CFLAGS="-march=x86-64 -msse4.2 -mpopcnt -m64 -mtune=intel"
E_LDFLAGS=
EXTRA="--disable-asm"

if [ "$ALL" == "YES" ]; then
build_one "$BUILD_ROOT" "$PREFIX" "$CROSS_PREFIX" "$ARCH" "$SYSROOT" \
"$E_CFLAGS" "$E_LDFLAGS" "$EXTRA"
fi

###############################################################################
#
# MIPS_64 build configuration
#
###############################################################################
PREFIX=$BASE/install/mips64
BUILD_ROOT=$BASE/build/mips64
SYSROOT=$NDK/platforms/android-$PLATFORM/arch-mips64/
TOOLCHAIN=$NDK/toolchains/mips64el-linux-android-4.9/prebuilt/darwin-$HOST_ARCH
CROSS_PREFIX=$TOOLCHAIN/bin/mips64el-linux-android-
ARCH=mips64
E_CFLAGS="-fno-strict-aliasing -fmessage-length=0 -fno-inline-functions-called-once -frerun-cse-after-loop -frename-registers"
E_LDFLAGS=
EXTRA="--cpu=mips64r6 \
--enable-runtime-cpudetect \
--enable-yasm \
--disable-asm \
--disable-mipsfpu \
--disable-mipsdsp \
--disable-mipsdspr2"

if [ "$ALL" == "YES" ]; then
build_one "$BUILD_ROOT" "$PREFIX" "$CROSS_PREFIX" "$ARCH" "$SYSROOT" \
"$E_CFLAGS" "$E_LDFLAGS" "$EXTRA"
fi
