# MinGW-w64 i686 toolchain stack
# This element provides the complete MinGW-w64 toolchain for cross-compiling
# C/C++ programs to Windows 32-bit (i686-w64-mingw32)
kind: stack

depends:
- toolchains/mingw/binutils-i686.bst
- toolchains/mingw/mingw-w64-headers-i686.bst
- toolchains/mingw/mingw-w64-crt-i686.bst
- toolchains/mingw/winpthreads-i686.bst
- toolchains/mingw/gcc-i686.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
