# Rust Windows i686 Cross-Compilation Stack
#
# This stack provides everything needed to cross-compile Rust programs
# to Windows 32-bit (i686-pc-windows-gnu target).
#
# Usage in your element:
# ----------------------
#   kind: cargo
#
#   build-depends:
#   - toolchains/rust-windows-i686-stack.bst
#
#   variables:
#     cargo-install-local: >-
#       --target=i686-pc-windows-gnu
#
#   environment:
#     PATH: "/usr/mingw-w64/i686-w64-mingw32/bin:/usr/bin:/bin"
#
# What's included:
# ----------------
#   - freedesktop-sdk Rust compiler (rustc, cargo)
#   - Minimal runtime environment
#   - Complete MinGW-w64 i686 toolchain (GCC, binutils, CRT, winpthreads)
#   - Rust standard library compiled for i686-pc-windows-gnu
#
# Output format: Windows PE32 executables (.exe)
#
# See elements/components/trainer-monitor.bst for a complete example.
#
kind: stack

depends:
# Rust compiler from freedesktop-sdk
- freedesktop-sdk.bst:components/rust.bst
# Minimal runtime for build environment
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
# Complete MinGW-w64 toolchain (provides cross-linker and runtime)
- toolchains/mingw/mingw-w64-i686.bst
# Rust standard library for Windows i686 target
- toolchains/rust-mingw-i686.bst
