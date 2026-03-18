# Trainer Monitor
#
# A Rust application cross-compiled to Windows 32-bit (i686-pc-windows-gnu).
# This element demonstrates how to build Rust applications for Windows
# using the MinGW-w64 cross-compilation toolchain.
#
# Output: Windows PE32 executable
#
# Build requirements:
#   - Rust compiler (from freedesktop-sdk)
#   - MinGW-w64 i686 toolchain (for Windows target)
#   - Rust standard library for i686-pc-windows-gnu
#
# Repository: https://github.com/DeckCheatz/trainer-monitor
#
kind: cargo

build-depends:
# Host GCC for any native compilation steps
- freedesktop-sdk.bst:components/gcc.bst
# Strip utility (though Windows binaries may not need it)
- freedesktop-sdk.bst:components/stripper.bst
# Complete Rust Windows i686 cross-compilation stack
- toolchains/rust-windows-i686-stack.bst

depends:
# Minimal runtime for build environment
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  # Configure cargo to cross-compile to Windows 32-bit
  cargo-install-local: >-
    --target=i686-pc-windows-gnu

environment:
  # Add MinGW toolchain to PATH so cargo can find the linker
  # The linker (i686-w64-mingw32-gcc) must be accessible
  PATH: "/usr/mingw-w64/i686-w64-mingw32/bin:/usr/bin:/bin"

sources:
# Main application source code
- kind: git_repo
  url: github:DeckCheatz/trainer-monitor.git
  track: main
  ref: 56dea9a0838a300e9dcc9273df1f4a4ed3cfdf63

# Vendored cargo dependencies (cargo2 source plugin)
# This ensures reproducible builds by pinning exact dependency versions
- kind: cargo2
  ref:
  - kind: registry
    name: anyhow
    version: 1.0.102
    sha: 7f202df86484c868dbad7eaa557ef785d5c66295e41b460ef922eca0723b842c
  - kind: registry
    name: proc-macro2
    version: 1.0.106
    sha: 8fd00f0bb2e90d81d1044c2b32617f68fcb9fa3bb7640c23e9c748e53fb30934
  - kind: registry
    name: quote
    version: 1.0.44
    sha: 21b2ebcf727b7760c461f091f9f0f539b77b8e87f2fd88131e7f1b433b3cece4
  - kind: registry
    name: syn
    version: 2.0.117
    sha: e665b8803e7b1d2a727f4023456bbbbe74da67099c585258af0ad9c5013b9b99
  - kind: registry
    name: thiserror
    version: 2.0.18
    sha: 4288b5bcbc7920c07a1149a35cf9590a2aa808e0bc1eafaade0b80947865fbc4
  - kind: registry
    name: thiserror-impl
    version: 2.0.18
    sha: ebc4ee7f67670e9b64d05fa4253e753e016c6c95ff35b89b7941d6b856dec1d5
  - kind: registry
    name: unicode-ident
    version: 1.0.24
    sha: e6e4313cd5fcd3dad5cafa179702e2b244f760991f45397d14d4ebf38247da75
