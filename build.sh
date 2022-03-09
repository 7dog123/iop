#!/bin/sh

echo "Binutils"
REPO_URL="https://github.com/ps2dev/binutils-gdb.git"
REPO_FOLDER="binutils-gdb"
BRANCH_NAME="iop-v2.35.2"

echo "Cloneing Binutils repo branch."
if test ! -d "$REPO_FOLDER"; then
  git clone --depth 1 -b $BRANCH_NAME $REPO_URL && cd "$REPO_FOLDER" || exit 1
else
  cd "$REPO_FOLDER" && git fetch origin && git reset --hard "origin/${BRANCH_NAME}" && git checkout "$BRANCH_NAME" || exit 1
fi

cd ..

PS2DEV=$GITHUB_WORKSPACE
TARGET_ALIAS="iop"
TARGET="mipsel-ps2-irx"

# Only choose one of these, depending on your build machine...
#export TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/darwin-x86_64
export TOOLCHAIN=$ANDROID_NDK_LATEST_HOME/toolchains/llvm/prebuilt/linux-x86_64
# Only choose one of these, depending on your device...
#export HOST=aarch64-linux-android
#export HOST=armv7a-linux-androideabi
#export HOST=i686-linux-android
export HOST=x86_64-linux-android
# Set this to your minSdkVersion.
export API=21
# Configure and build.
export AR=$TOOLCHAIN/bin/llvm-ar
export CC=$TOOLCHAIN/bin/$TARGET$API-clang
export AS=$CC
export CXX=$TOOLCHAIN/bin/$TARGET$API-clang++
export LD=$TOOLCHAIN/bin/ld
export RANLIB=$TOOLCHAIN/bin/llvm-ranlib
export STRIP=$TOOLCHAIN/bin/llvm-strip

PROC_NR=$(getconf _NPROCESSORS_ONLN)

## Create and enter the toolchain/build directory
rm -rf build-$TARGET && mkdir build-$TARGET && cd build-$TARGET || { exit 1; }

echo "Compiling binutils."
../binutils-gdb/configure \
  --quiet \
  --prefix="$PS2DEV/$TARGET_ALIAS" \
  --target="$TARGET" \
  --host="$HOST" \
  --disable-separate-code \
  --disable-sim \
  --disable-nls || { exit 1; }

## Compile and install.
echo "Cleaning old files."
make --quiet -j $PROC_NR clean          || { exit 1; }
echo "Build binutils."
make --quiet -j $PROC_NR CFLAGS="$CFLAGS -D_FORTIFY_SOURCE=0" || { exit 1; }
echo "Installing binutils."
make --quiet -j $PROC_NR install-strip  || { exit 1; }
echo "Clean files."
make --quiet -j $PROC_NR clean          || { exit 1; }

## Exit the build directory.
cd .. || { exit 1; }


echo "GCC"

REPO_URL="https://github.com/ps2dev/gcc.git"
REPO_FOLDER="gcc"
BRANCH_NAME="iop-v11.2.0"

echo "Cloneing GCC repo branch."
if test ! -d "$REPO_FOLDER"; then
  git clone --depth 1 -b $BRANCH_NAME $REPO_URL && cd "$REPO_FOLDER" || exit 1
else
  cd "$REPO_FOLDER" && git fetch origin && git reset --hard "origin/${BRANCH_NAME}" && git checkout "$BRANCH_NAME" || exit 1
fi

echo "download gcc prerequisites"
./contrib/download_prerequisites

cd ..

rm -rf build-$TARGET-stage1 && mkdir build-$TARGET-stage1 && cd build-$TARGET-stage1 || { exit 1; }

echo "Configure GCC"
../gcc/configure \
  --quiet \
  --prefix="$PS2DEV/$TARGET_ALIAS" \
  --target="$TARGET" \
  --host="$HOST" \
  --enable-languages="c" \
  --with-float=soft \
  --with-headers=no \
  --without-newlib \
  --without-cloog \
  --without-ppl \
  --disable-decimal-float \
  --disable-libada \
  --disable-libatomic \
  --disable-libffi \
  --disable-libgomp \
  --disable-libmudflap \
  --disable-libquadmath \
  --disable-libssp \
  --disable-libstdcxx-pch \
  --disable-multilib \
  --disable-shared \
  --disable-threads \
  --disable-target-libiberty \
  --disable-target-zlib \
  --disable-nls || { exit 1; }

## Compile and install.
echo "Cleaning old files."
make --quiet -j $PROC_NR clean          || { exit 1; }
echo "Build GCC."
make --quiet -j $PROC_NR all
echo "Installing GCC."
make --quiet -j $PROC_NR install-strip  || { exit 1; }
echo "Clean files."
make --quiet -j $PROC_NR clean          || { exit 1; }

## Exit the build directory.
cd .. || { exit 1; }

