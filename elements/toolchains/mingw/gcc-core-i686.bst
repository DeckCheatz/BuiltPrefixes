# GCC core (C only) for i686-w64-mingw32 - Stage 1 compiler
# This is needed to build mingw-w64 CRT before we can build the full GCC
kind: autotools

# Allow overlap with binutils info/dir file
public:
  bst:
    overlap-whitelist:
    - "%{mingw-prefix}/share/info/dir"

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/gcc.bst
- freedesktop-sdk.bst:components/bison.bst
- freedesktop-sdk.bst:components/flex.bst
- freedesktop-sdk.bst:components/stripper.bst
- freedesktop-sdk.bst:components/texinfo.bst
- toolchains/mingw/binutils-i686.bst
- toolchains/mingw/mingw-w64-headers-i686.bst

variables:
  mingw-target: i686-w64-mingw32
  mingw-prefix: "%{prefix}/mingw-w64/%{mingw-target}"

environment-nocache:
- MAXJOBS

environment:
  MAXJOBS: '%{max-jobs}'
  PATH: "%{mingw-prefix}/bin:/usr/bin:/bin"

config:
  configure-commands:
  - |
    mkdir build && cd build
    ../configure \
      --prefix="%{mingw-prefix}" \
      --target="%{mingw-target}" \
      --with-sysroot="%{mingw-prefix}" \
      --enable-languages=c,lto \
      --enable-lto \
      --disable-multilib \
      --disable-nls \
      --disable-shared \
      --disable-threads \
      --disable-libssp \
      --disable-libgomp \
      --disable-libquadmath \
      --disable-libatomic \
      --without-headers \
      --with-newlib \
      --disable-sjlj-exceptions \
      --with-dwarf2

  build-commands:
  - make -C build -j${MAXJOBS} all-gcc

  install-commands:
  - make -C build DESTDIR="%{install-root}" install-gcc

  strip-commands: []

sources:
# GCC source
- kind: git_repo
  url: gcc_gnu_org:gcc.git
  track: releases/gcc-14
  ref: releases/gcc-14.3.0-542-g0e0aaa3b26afe7fdf0f65385425af2ecaa9f62ea
# GMP - required for GCC
- kind: tar
  url: tar_https:gmplib.org/download/gmp/gmp-6.3.0.tar.xz
  ref: a3c2b80201b89e68616f4ad30bc66aee4927c3ce50e33929ca819d5c43538898
  directory: gmp
# MPFR - required for GCC
- kind: tar
  url: tar_https:www.mpfr.org/mpfr-current/mpfr-4.2.2.tar.xz
  ref: b67ba0383ef7e8a8563734e2e889ef5ec3c3b898a01d00fa0a6869ad81c6ce01
  directory: mpfr
# MPC - required for GCC
- kind: tar
  url: tar_https:ftp.gnu.org/gnu/mpc/mpc-1.3.1.tar.gz
  ref: ab642492f5cf882b74aa0cb730cd410a81edcdbec895183ce930e706c1c759b8
  directory: mpc
# ISL - required for loop optimization
- kind: tar
  url: tar_https:libisl.sourceforge.io/isl-0.27.tar.xz
  ref: 6d8babb59e7b672e8cb7870e874f3f7b813b6e00e6af3f8b04f7579965643d5c
  directory: isl
