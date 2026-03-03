# GNU Binutils for i686-w64-mingw32 cross-compilation
kind: autotools

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/gcc.bst
- freedesktop-sdk.bst:components/bison.bst
- freedesktop-sdk.bst:components/flex.bst
- freedesktop-sdk.bst:components/texinfo.bst

variables:
  mingw-target: i686-w64-mingw32
  mingw-prefix: "%{prefix}/mingw-w64/%{mingw-target}"

environment-nocache:
- MAXJOBS

environment:
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

  strip-commands: []

sources:
- kind: git_repo
  url: sourceware:binutils-gdb.git
  track: binutils-2_44-branch
  ref: binutils-2_44-190-g9256a4b356856649ec1e3e4dd9371ce29603cfda
