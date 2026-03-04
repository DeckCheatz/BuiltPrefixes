# GNU Binutils for i686-w64-mingw32 Cross-Compilation
#
# Provides the foundational binary utilities for the MinGW-w64 toolchain:
#   - as: GNU Assembler for i686 Windows targets
#   - ld: GNU Linker for creating Windows PE executables
#   - ar: Archive tool for creating static libraries (.a)
#   - objcopy, objdump, strip: Binary manipulation utilities
#   - dlltool: Creates import libraries from DLL exports
#
# This is the first component built in the MinGW-w64 toolchain bootstrap.
# No other MinGW components are required to build this.
#
# Installation prefix: /usr/mingw-w64/i686-w64-mingw32
#
# Source: GNU Binutils 2.44 branch
#
kind: autotools

build-depends:
# Standard autotools build environment
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
# Host GCC to compile binutils
- freedesktop-sdk.bst:components/gcc.bst
# Required for building binutils
- freedesktop-sdk.bst:components/bison.bst
- freedesktop-sdk.bst:components/flex.bst
- freedesktop-sdk.bst:components/texinfo.bst

variables:
  # Target triplet for Windows 32-bit
  mingw-target: i686-w64-mingw32
  # Installation prefix for the cross-toolchain
  mingw-prefix: "%{prefix}/mingw-w64/%{mingw-target}"

# MAXJOBS should not affect cache key
environment-nocache:
- MAXJOBS

environment:
  # Parallel build jobs
  MAXJOBS: '%{max-jobs}'

config:
  configure-commands:
  - |
    mkdir build && cd build
    ../configure \
      --prefix="%{mingw-prefix}" \
      --target="%{mingw-target}" \
      --with-sysroot="%{mingw-prefix}" \
      --disable-multilib \
      --disable-nls \
      --disable-werror \
      --disable-gdb \
      --disable-gdbserver \
      --disable-libdecnumber \
      --disable-sim \
      --enable-64-bit-bfd \
      --enable-lto \
      --enable-plugins

  build-commands:
  - make -C build -j${MAXJOBS}

  install-commands:
  - make -C build DESTDIR="%{install-root}" install

  # Disable stripping - can cause issues with cross-toolchain binaries
  strip-commands: []

sources:
# GNU Binutils from sourceware.org
- kind: git_repo
  url: sourceware:binutils-gdb.git
  track: binutils-2_44-branch
  ref: binutils-2_44-190-g9256a4b356856649ec1e3e4dd9371ce29603cfda
