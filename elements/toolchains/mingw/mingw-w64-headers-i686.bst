# MinGW-w64 Headers for i686 Windows Target
#
# Provides Windows API header files for cross-compilation:
#   - Windows SDK headers (windows.h, etc.)
#   - C runtime headers
#   - IDL (Interface Definition Language) headers
#   - Secure API extensions (_s suffix functions)
#
# These headers define Windows types, constants, and function declarations
# needed to compile code targeting Windows.
#
# Build order: binutils -> headers (this) -> gcc-core -> crt -> ...
#
# Creates symlink: %{mingw-prefix}/mingw -> %{mingw-prefix}
# (Required by GCC to locate headers during cross-compilation)
#
# Source: mingw-w64 project
#
kind: autotools

build-depends:
# Standard autotools build environment
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/stripper.bst
# Binutils must be built first (provides target definition)
- toolchains/mingw/binutils-i686.bst

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
    cd mingw-w64-headers
    ./configure \
      --prefix="%{mingw-prefix}" \
      --host="%{mingw-target}" \
      --enable-sdk=all \
      --enable-idl \
      --enable-secure-api

  build-commands:
  - make -C mingw-w64-headers -j${MAXJOBS}

  install-commands:
  - make -C mingw-w64-headers DESTDIR="%{install-root}" install
  # Create symlink for GCC to find the headers
  # GCC looks for headers in <sysroot>/mingw/include
  - |
    ln -sfv "%{mingw-prefix}" "%{install-root}%{mingw-prefix}/mingw"

sources:
# mingw-w64 project repository
- kind: git_repo
  url: github:mingw-w64/mingw-w64.git
  track: "v*.*.*"
  ref: v14.0.0-0-g9b3dd0125792fe94d16cacdc596dbd42fca1b369
