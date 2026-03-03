# Complete Rust toolchain for cross-compiling to Windows 32-bit
# This stack provides everything needed to build Rust programs targeting
# i686-pc-windows-gnu (Windows 32-bit with MinGW)
#
# Usage in your element:
#   build-depends:
#   - toolchains/rust-windows-i686-stack.bst
#
# Then build with:
#   cargo build --target i686-pc-windows-gnu
#
kind: stack

depends:
- freedesktop-sdk.bst:components/rust.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- toolchains/mingw/mingw-w64-i686.bst
- toolchains/rust-mingw-i686.bst
