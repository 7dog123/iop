#!/bin/sh

 File  58 lines (47 sloc)  1.98 KB
#!/bin/sh

REPO_URL="https://github.com/ps2dev/binutils-gdb.git"
REPO_FOLDER="binutils-gdb"
BRANCH_NAME="iop-v2.35.2"

if test ! -d "$REPO_FOLDER"; then
  git clone --depth 1 -b $BRANCH_NAME $REPO_URL && cd "$REPO_FOLDER" || exit 1
else
  cd "$REPO_FOLDER" && git fetch origin && git reset --hard "origin/${BRANCH_NAME}" && git checkout "$BRANCH_NAME" || exit 1
fi

cd ..

PS2DEV=$GITHUB_WORKSPACE
TARGET_ALIAS="iop"
TARGET="mipsel-ps2-irx"

chmod 755 config.guess config.sub
cp -rv $GITHUB_WORKSPACE/config.guess $GITHUB_WORKSPACE/binutils-gdb
cp -rv $GITHUB_WORKSPACE/config.sub $GITHUB_WORKSPACE/binutils-gdb

export NDK_HOME=$GITHUB_WORKSPACE/android-ndk-r11c
export CROSS_SYSROOT=${NDK_HOME}/toolchains/x86_64-4.9/prebuilt/linux-x86_64/bin/
export CROSS_COMPILE=${CROSS_SYSROOT}/x86_64-linux-android-
export PATH=${NDK_HOME}/toolchains/x86_64-4.9/prebuilt/linux-x86_64/bin:$PATH
export SYSROOT=${NDK_HOME}/platforms/android-21/arch-x86_64
export CC="${CROSS_COMPILE}gcc --sysroot=${SYSROOT}"
export CXX="${CROSS_COMPILE}g++ --sysroot=${SYSROOT}"
export AR="${CROSS_COMPILE}ar"
export AS="${CC} --sysroot=${SYSROOT}"
export LD="${CROSS_COMPILE}ld"
export RANLIB="${CROSS_COMPILE}ranlib"
export STRIP="${CROSS_COMPILE}strip"
#export CFLAGS="-D__ANDROID_API__=21"
PATH=$NDK_HOME/toolchains/x86_64-4.9/prebuilt/linux-x86_64/bin:$PATH

PROC_NR=$(getconf _NPROCESSORS_ONLN)

## Create and enter the toolchain/build directory
rm -rf build-$TARGET && mkdir build-$TARGET && cd build-$TARGET || { exit 1; }

../binutils-gdb/configure \
  --quiet \
  --prefix="$PS2DEV/$TARGET_ALIAS" \
  --target="$TARGET" \
  --host=x86_64-linux-android \
  --disable-separate-code \
  --disable-sim \
  --disable-nls \
  $TARG_XTRA_OPTS || { exit 1; }

## Compile and install.
make --quiet -j $PROC_NR clean          || { exit 1; }
make --quiet -j $PROC_NR CFLAGS="$CFLAGS -D_FORTIFY_SOURCE=0" || { exit 1; }
make --quiet -j $PROC_NR install-strip  || { exit 1; }
make --quiet -j $PROC_NR clean          || { exit 1; }

## Exit the build directory.
cd .. || { exit 1; }
