# Winpthreads - POSIX Threads Implementation for Windows
#
# Provides a POSIX threads (pthreads) implementation for Windows:
#   - pthread_create, pthread_join, pthread_mutex_*, etc.
#   - Condition variables, barriers, read-write locks
#   - Thread-local storage (pthread_key_*)
#   - Enables GCC's POSIX threading model (--enable-threads=posix)
#
# Output libraries:
#   - libpthread.a (static library)
#   - libwinpthread-1.dll (shared library)
#
# Build order: binutils -> headers -> gcc-core -> crt -> winpthreads (this) -> gcc
#
# Important: LDFLAGS is cleared because freedesktop-sdk sets Linux-specific
# linker flags (-z relro, -z now) that MinGW's ld doesn't understand.
#
# Source: mingw-w64 project (mingw-w64-libraries/winpthreads)
#
kind: autotools

# Allow overlap with mingw-w64-headers pthread stubs
# The headers package includes stub pthread headers that winpthreads replaces
public:
  bst:
    overlap-whitelist:
    - "%{mingw-prefix}/include/pthread_signal.h"
    - "%{mingw-prefix}/include/pthread_time.h"
    - "%{mingw-prefix}/include/pthread_unistd.h"

build-depends:
# Standard autotools build environment
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/flex.bst
- freedesktop-sdk.bst:components/stripper.bst
# MinGW components that must be built first
- toolchains/mingw/binutils-i686.bst
- toolchains/mingw/mingw-w64-headers-i686.bst
- toolchains/mingw/mingw-w64-crt-i686.bst
# Stage 1 GCC is required to compile winpthreads
- toolchains/mingw/gcc-core-i686.bst

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
  # Add MinGW tools to PATH
  PATH: "%{mingw-prefix}/bin:/usr/bin:/bin"
  # Use the cross-compiler
  CC: "%{mingw-target}-gcc"
  CXX: "%{mingw-target}-g++"
  AR: "%{mingw-target}-ar"
  RANLIB: "%{mingw-target}-ranlib"
  # Override LDFLAGS to remove Linux-specific security flags that MinGW ld doesn't understand
  # freedesktop-sdk sets: -Wl,-z,relro,-z,now which are ELF-specific
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
# mingw-w64 project repository
- kind: git_repo
  url: github:mingw-w64/mingw-w64.git
  track: master
  ref: v13.0.0-560-g3197fc7d6146d2c53082e302112748a157ca0074
