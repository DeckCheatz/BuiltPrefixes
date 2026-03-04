# MinGW-w64 i686 Toolchain Stack
#
# This stack element aggregates all components of the MinGW-w64 cross-compilation
# toolchain for Windows 32-bit (i686-w64-mingw32) targets.
#
# Use this as a single dependency to get the complete toolchain:
#
#   build-depends:
#   - toolchains/mingw/mingw-w64-i686.bst
#
# Included components:
#   - binutils: Assembler, linker, and binary utilities
#   - mingw-w64-headers: Windows API headers
#   - mingw-w64-crt: C runtime library
#   - winpthreads: POSIX threads implementation
#   - gcc: Full C/C++ compiler with runtime libraries
#
# Installation prefix: /usr/mingw-w64/i686-w64-mingw32
#
# After including this stack, you can cross-compile with:
#   i686-w64-mingw32-gcc -o program.exe program.c
#   i686-w64-mingw32-g++ -o program.exe program.cpp
#
kind: stack

depends:
# All MinGW-w64 toolchain components
- toolchains/mingw/binutils-i686.bst
- toolchains/mingw/mingw-w64-headers-i686.bst
- toolchains/mingw/mingw-w64-crt-i686.bst
- toolchains/mingw/winpthreads-i686.bst
- toolchains/mingw/gcc-i686.bst
# Include autotools for convenient configure/make builds
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
