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
PLATFORM=21
fi

if [ -z $MAKE_OPTS ]; then
MAKE_OPTS="-j4"
fi

if [ -z $ALL ]; then
ALL="NO"
fi

function usage
{
echo "$0 [-a <ndk>] [-h <host arch>] [-m <make opts>] [-p <android platform>] [-v]"
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

touch $BASE/install.log
echo "*** ffmpeg-android-macosx ***"
echo "Beginning Build"
echo "-----------------------------------------------"

echo "Refreshing FFMpeg 3.2 Library"
echo "-----------------------------------------------"
cd $BASE/FFmpeg
git checkout release/3.2 > $BASE/install.log 2>&1
git pull > $BASE/install.log 2>&1
cd ..
git submodule update --init > $BASE/install.log 2>&1
git submodule update --remote > $BASE/install.log 2>&1

echo "-----------------------------------------------"
echo "Building with:"
echo "-----------------------------------------------"
echo "HOST_ARCH=$HOST_ARCH"
echo "PLATFORM=$PLATFORM"
echo "MAKE_OPTS=$MAKE_OPTS"
echo "ANDROID_NDK=$ANDROID_NDK"
echo "64-BIT ARCHES: $ALL"
echo "-----------------------------------------------"

echo "-----------------------------------------------" > $BASE/install.log 2>&1
echo "Building with:"  > $BASE/install.log 2>&1
echo "-----------------------------------------------" > $BASE/install.log 2>&1
echo "HOST_ARCH=$HOST_ARCH" > $BASE/install.log 2>&1
echo "PLATFORM=$PLATFORM" > $BASE/install.log 2>&1
echo "MAKE_OPTS=$MAKE_OPTS" > $BASE/install.log 2>&1
echo "ANDROID_NDK=$ANDROID_NDK" > $BASE/install.log 2>&1
echo "64-BIT ARCHES: $ALL" > $BASE/install.log 2>&1
echo "-----------------------------------------------" > $BASE/install.log 2>&1


echo "Applying Config Patches"
echo "-----------------------------------------------"

echo "Applying Config Patches" > $BASE/install.log 2>&1
echo "-----------------------------------------------" > $BASE/install.log 2>&1

cd $BASE/FFmpeg

# Save original configuration file
# or restore original before applying patches.
if [ ! -f configure.bak ]; then
echo "Saving original configure file to configure.bak" > $BASE/install.log 2>&1
cp configure configure.bak > $BASE/install.log 2>&1
else
echo "Restoring original configure file from configure.bak" > $BASE/install.log 2>&1
cp configure.bak configure > $BASE/install.log 2>&1
fi

patch -p1 < $BASE/patches/config.patch > $BASE/install.log 2>&1

if [ ! -f library.mak.bak ]; then
echo "Saving original library.mak file to library.mak.bak" > $BASE/install.log 2>&1
cp library.mak library.mak.bak > $BASE/install.log 2>&1
else
echo "Restoring original library.mak file from library.mak.bak" > $BASE/install.log 2>&1
cp library.mak.bak library.mak > $BASE/install.log 2>&1
fi

patch -p1 < $BASE/patches/library.mak.patch > $BASE/install.log 2>&1

echo "Removing old build data"
echo "-----------------------------------------------"

echo "Removing old build data" > $BASE/install.log 2>&1
echo "-----------------------------------------------" > $BASE/install.log 2>&1

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
--disable-avfilter \
--disable-swscale \
--disable-muxers \
--enable-rdft \
--enable-demuxer=aac \
--enable-demuxer=ac3 \
--enable-demuxer=ape \
--enable-demuxer=asf \
--enable-demuxer=flac \
--enable-demuxer=matroska_audio \
--enable-demuxer=mp3 \
--enable-demuxer=mpc \
--enable-demuxer=mov \
--enable-demuxer=mpc8 \
--enable-demuxer=ogg \
--enable-demuxer=tta \
--enable-demuxer=wav \
--enable-demuxer=wv \
--disable-bsfs \
--disable-filters \
--disable-parsers \
--enable-parser=aac \
--enable-parser=ac3 \
--enable-parser=mpegaudio \
--disable-protocols \
--enable-protocol=file \
--disable-indevs \
--disable-outdevs \
--disable-encoders \
--enable-decoder=aac \
--enable-decoder=ac3 \
--enable-decoder=alac \
--enable-decoder=ape \
--enable-decoder=flac \
--enable-decoder=mp1 \
--enable-decoder=mp2 \
--enable-decoder=mp3 \
--enable-decoder=mpc7 \
--enable-decoder=mpc8 \
--enable-decoder=tta \
--enable-decoder=vorbis \
--enable-decoder=wavpack \
--enable-decoder=wmav1 \
--enable-decoder=wmav2 \
--enable-decoder=pcm_alaw \
--enable-decoder=pcm_dvd \
--enable-decoder=pcm_f32be \
--enable-decoder=pcm_f32le \
--enable-decoder=pcm_f64be \
--enable-decoder=pcm_f64le \
--enable-decoder=pcm_s16be \
--enable-decoder=pcm_s16le \
--enable-decoder=pcm_s16le_planar \
--enable-decoder=pcm_s24be \
--enable-decoder=pcm_daud \
--enable-decoder=pcm_s24le \
--enable-decoder=pcm_s32be \
--enable-decoder=pcm_s32le \
--enable-decoder=pcm_s8 \
--enable-decoder=pcm_u16be \
--enable-decoder=pcm_u16le \
--enable-decoder=pcm_u24be \
--enable-decoder=pcm_u24le \
--enable-decoder=rawvideo \
--enable-symver \
--cross-prefix=$3 \
--target-os=linux \
--enable-pic \
--arch=$4 \
--enable-cross-compile \
--sysroot=$5 \
--extra-cflags="-Os $6" \
--extra-ldflags="$7" \
$8 > $BASE/install.log 2>&1

make clean > $BASE/install.log 2>&1
make $MAKE_OPTS > $BASE/install.log 2>&1
make install > $BASE/install.log 2>&1
}

NDK=$ANDROID_NDK


###############################################################################
#
# ARM build configuration
#
###############################################################################
PREFIX=$BASE/install/armeabi
BUILD_ROOT=$BASE/build/armeabi
SYSROOT=$NDK/platforms/android-$PLATFORM/arch-arm/
TOOLCHAIN=$NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/darwin-$HOST_ARCH
CROSS_PREFIX=$TOOLCHAIN/bin/arm-linux-androideabi-
ARCH=arm
E_CFLAGS=
E_LDFLAGS=
EXTRA=

echo "Building: ARM"
echo "Building: ARM" > install.log

build_one "$BUILD_ROOT" "$PREFIX" "$CROSS_PREFIX" "$ARCH" "$SYSROOT" \
"$E_CFLAGS" "$E_LDFLAGS" "$EXTRA"

echo "-----------------------------------------------"

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

echo "Building: ARM-v7a"
echo "Building: ARM-v7a" > install.log

build_one "$BUILD_ROOT" "$PREFIX" "$CROSS_PREFIX" "$ARCH" "$SYSROOT" \
"$E_CFLAGS" "$E_LDFLAGS" "$EXTRA"

echo "-----------------------------------------------"

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

echo "Building: x86"
echo "Building: x86" > install.log

build_one "$BUILD_ROOT" "$PREFIX" "$CROSS_PREFIX" "$ARCH" "$SYSROOT" \
"$E_CFLAGS" "$E_LDFLAGS" "$EXTRA"

echo "-----------------------------------------------"

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

echo "Building: MIPS"
echo "Building: MIPS" > install.log

build_one "$BUILD_ROOT" "$PREFIX" "$CROSS_PREFIX" "$ARCH" "$SYSROOT" \
"$E_CFLAGS" "$E_LDFLAGS" "$EXTRA"

echo "-----------------------------------------------"

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
echo "Building: ARM64-v8a"
echo "Building: ARM64-v8a" > install.log
build_one "$BUILD_ROOT" "$PREFIX" "$CROSS_PREFIX" "$ARCH" "$SYSROOT" \
"$E_CFLAGS" "$E_LDFLAGS" "$EXTRA"
echo "-----------------------------------------------"
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
echo "Building: x86_64"
echo "Building: x86_64" > install.log
build_one "$BUILD_ROOT" "$PREFIX" "$CROSS_PREFIX" "$ARCH" "$SYSROOT" \
"$E_CFLAGS" "$E_LDFLAGS" "$EXTRA"
echo "-----------------------------------------------"
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
echo "Building: MIPS_64"
echo "Building: MIPS_64" > install.log
build_one "$BUILD_ROOT" "$PREFIX" "$CROSS_PREFIX" "$ARCH" "$SYSROOT" \
"$E_CFLAGS" "$E_LDFLAGS" "$EXTRA"
echo "-----------------------------------------------"
fi
