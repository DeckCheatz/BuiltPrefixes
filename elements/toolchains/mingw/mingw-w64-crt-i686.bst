# MinGW-w64 CRT (C Runtime) for i686 Windows target
kind: autotools

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/flex.bst
- freedesktop-sdk.bst:components/stripper.bst
- toolchains/mingw/binutils-i686.bst
- toolchains/mingw/mingw-w64-headers-i686.bst
- toolchains/mingw/gcc-core-i686.bst

variables:
  mingw-target: i686-w64-mingw32
  mingw-prefix: "%{prefix}/mingw-w64/%{mingw-target}"

environment-nocache:
- MAXJOBS

environment:
  MAXJOBS: '%{max-jobs}'
  PATH: "%{mingw-prefix}/bin:/usr/bin:/bin"
  CC: "%{mingw-target}-gcc"
  CXX: "%{mingw-target}-g++"
  AR: "%{mingw-target}-ar"
  RANLIB: "%{mingw-target}-ranlib"
  # Help configure find the ar interface
  am_cv_ar_interface: ar
  # Disable stack protection - MinGW SSP code requires symbols not available in the CRT
  CFLAGS: "-O2 -g -fno-stack-protector"
  CXXFLAGS: "-O2 -g -fno-stack-protector"

config:
  configure-commands:
  - |
    cd mingw-w64-crt
    ./configure \
      --prefix="%{mingw-prefix}" \
      --host="%{mingw-target}" \
      --with-sysroot="%{mingw-prefix}" \
      --enable-lib32 \
      --disable-lib64 \
      --enable-wildcard \
      --disable-dependency-tracking

  build-commands:
  - make -C mingw-w64-crt -j${MAXJOBS}

  install-commands:
  - make -C mingw-w64-crt DESTDIR="%{install-root}" install

sources:
- kind: git_repo
  url: github:mingw-w64/mingw-w64.git
  track: master
  ref: v13.0.0-560-g3197fc7d6146d2c53082e302112748a157ca0074
