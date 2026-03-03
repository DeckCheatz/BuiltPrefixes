# Winpthreads - POSIX threads implementation for Windows
kind: autotools

# Allow overlap with mingw-w64-headers pthread stubs
public:
  bst:
    overlap-whitelist:
    - "%{mingw-prefix}/include/pthread_signal.h"
    - "%{mingw-prefix}/include/pthread_time.h"
    - "%{mingw-prefix}/include/pthread_unistd.h"

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/flex.bst
- freedesktop-sdk.bst:components/stripper.bst
- toolchains/mingw/binutils-i686.bst
- toolchains/mingw/mingw-w64-headers-i686.bst
- toolchains/mingw/mingw-w64-crt-i686.bst
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
  # Override LDFLAGS to remove Linux-specific security flags that MinGW ld doesn't understand
  LDFLAGS: ""
  CFLAGS: "-O2 -g"
  CXXFLAGS: "-O2 -g"

config:
  configure-commands:
  - |
    cd mingw-w64-libraries/winpthreads
    ./configure \
      --prefix="%{mingw-prefix}" \
      --host="%{mingw-target}" \
      --enable-static \
      --enable-shared

  build-commands:
  - make -C mingw-w64-libraries/winpthreads -j${MAXJOBS}

  install-commands:
  - make -C mingw-w64-libraries/winpthreads DESTDIR="%{install-root}" install

sources:
- kind: git_repo
  url: github:mingw-w64/mingw-w64.git
  track: master
  ref: v13.0.0-560-g3197fc7d6146d2c53082e302112748a157ca0074
