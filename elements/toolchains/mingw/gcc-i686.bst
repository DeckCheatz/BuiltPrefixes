# Full GCC for i686-w64-mingw32 Cross-Compilation
#
# This is the complete GCC cross-compiler with full language and runtime support:
#   - Languages: C, C++, LTO (Link-Time Optimization)
#   - Threading: POSIX (via winpthreads)
#   - C++ Standard Library: libstdc++ with full features
#   - Runtime libraries: libgcc, libstdc++, etc.
#
# Exception handling: DWARF2 (--with-dwarf2 --disable-sjlj-exceptions)
# This is critical for Rust compatibility. Rust expects standard _Unwind_*
# symbols, not the SJLJ variants (__Unwind_SjLj_*).
#
# Build order: binutils -> headers -> gcc-core -> crt -> winpthreads -> gcc (this)
#
# Output tools (in %{mingw-prefix}/bin):
#   - i686-w64-mingw32-gcc: C compiler
#   - i686-w64-mingw32-g++: C++ compiler
#   - i686-w64-mingw32-cpp: C preprocessor
#   - i686-w64-mingw32-gcov: Coverage tool
#   - Convenience symlinks: mingw32-gcc, mingw32-g++, etc.
#
# Source: GCC 14.3.0 with GMP, MPFR, MPC, ISL dependencies
#
kind: autotools

# Allow overlap with binutils info/dir file
public:
  bst:
    overlap-whitelist:
    - "%{mingw-prefix}/share/info/dir"

build-depends:
# Standard autotools build environment
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
# Host GCC to compile the cross-compiler
- freedesktop-sdk.bst:components/gcc.bst
# Required build tools
- freedesktop-sdk.bst:components/bison.bst
- freedesktop-sdk.bst:components/flex.bst
- freedesktop-sdk.bst:components/texinfo.bst
- freedesktop-sdk.bst:components/stripper.bst
# All MinGW components must be built first
- toolchains/mingw/binutils-i686.bst
- toolchains/mingw/mingw-w64-headers-i686.bst
- toolchains/mingw/mingw-w64-crt-i686.bst
- toolchains/mingw/winpthreads-i686.bst

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
  # Add MinGW tools to PATH (needed for building runtime libraries)
  PATH: "%{mingw-prefix}/bin:/usr/bin:/bin"

config:
  configure-commands:
  - |
    mkdir build && cd build
    ../configure \
      --prefix="%{mingw-prefix}" \
      --target="%{mingw-target}" \
      --with-sysroot="%{mingw-prefix}" \
      --enable-languages=c,c++,lto \
      --enable-lto \
      --enable-threads=posix \
      --enable-fully-dynamic-string \
      --enable-libstdcxx-time=yes \
      --enable-libstdcxx-filesystem-ts=yes \
      --enable-cloog-backend=isl \
      --disable-multilib \
      --disable-nls \
      --disable-werror \
      --disable-symvers \
      --disable-libstdcxx-pch \
      --disable-libstdcxx-debug \
      --disable-win32-registry \
      --enable-shared \
      --enable-static \
      --with-gnu-as \
      --with-gnu-ld \
      --disable-sjlj-exceptions \
      --with-dwarf2

  build-commands:
  - make -C build -j${MAXJOBS}

  install-commands:
  - make -C build DESTDIR="%{install-root}" install
  # Create convenience symlinks for shorter command names
  - |
    cd "%{install-root}%{mingw-prefix}/bin"
    for prog in gcc g++ cpp gcov; do
      if [ -f "%{mingw-target}-${prog}" ]; then
        ln -sfv "%{mingw-target}-${prog}" "mingw32-${prog}"
      fi
    done

  # Disable stripping - stripper fails on hardlinked cross-compiler binaries
  # GCC creates hardlinks between some binaries, and strip can't handle them
  strip-commands: []

sources:
# GCC source from GNU
- kind: git_repo
  url: gcc_gnu_org:gcc.git
  track: releases/gcc-14
  ref: releases/gcc-14.3.0-682-gf8cc39faaa3cfa44efb484a60d2eb7684572b85c

# GMP - GNU Multiple Precision Arithmetic Library (required by GCC)
- kind: tar
  url: tar_https:ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.xz
  ref: a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898
  directory: gmp

# MPFR - Multiple Precision Floating-Point (required by GCC)
- kind: tar
  url: tar_https:www.mpfr.org/mpfr-current/mpfr-4.2.2.tar.xz
  ref: b67ba0383ef7e8a8563734e2e889ef5ec3c3b898a01d00fa0a6869ad81c6ce01
  directory: mpfr

# MPC - Multiple Precision Complex (required by GCC)
- kind: tar
  url: tar_https:ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz
  ref: ab642492f5cf882b74aa0cb730cd410a81edcdbec895183ce930e706c1c759b8
  directory: mpc

# ISL - Integer Set Library (required for loop optimizations)
- kind: tar
  url: tar_https:libisl.sourceforge.io/isl-0.27.tar.xz
  ref: 6d8babb59e7b672e8cb7870e874f3f7b813b6e00e6af3f8b04f7579965643d5c
  directory: isl
