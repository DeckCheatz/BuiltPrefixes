# MinGW-w64 C Runtime (CRT) for i686 Windows Target
#
# The C Runtime provides the foundational C library implementation:
#   - C standard library functions (printf, malloc, etc.)
#   - Program startup/shutdown code (crt0, crtbegin, crtend)
#   - Exception handling support
#   - Thread-local storage support
#   - Import libraries for Windows system DLLs
#
# Build order: binutils -> headers -> gcc-core -> crt (this) -> winpthreads -> gcc
#
# Important build flags:
#   - Stack protection disabled (-fno-stack-protector)
#     MinGW's SSP implementation requires symbols (write, _imp__rand_s)
#     that aren't available in the minimal CRT environment.
#
#   - 32-bit only (--enable-lib32 --disable-lib64)
#     This is an i686 (32-bit) toolchain.
#
# Source: mingw-w64 project
#
kind: autotools

build-depends:
# Standard autotools build environment
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/flex.bst
- freedesktop-sdk.bst:components/stripper.bst
# MinGW components that must be built first
- toolchains/mingw/binutils-i686.bst
- toolchains/mingw/mingw-w64-headers-i686.bst
# Stage 1 GCC is required to compile the CRT
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
  # Help configure find the ar interface
  am_cv_ar_interface: ar
  # Disable stack protection - MinGW SSP code requires symbols not available in the CRT
  # These symbols (write, _imp__rand_s) are used by libssp but aren't provided yet
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
# mingw-w64 project repository
- kind: git_repo
  url: github:mingw-w64/mingw-w64.git
  track: "v*.*.*"
  ref: v13.0.0-0-gde62c283f3383bd825c98518cb0a42ba071d4ac2
