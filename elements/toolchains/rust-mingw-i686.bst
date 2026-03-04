# Rust Standard Library for i686-pc-windows-gnu Target
#
# Builds the Rust standard library from source for cross-compiling Rust
# programs to Windows 32-bit using the MinGW-w64 toolchain.
#
# Why build from source?
# ----------------------
# Pre-built Rust target libraries from rustup have different compiler metadata
# than the freedesktop-sdk's rustc. This causes "can't find crate" errors because
# the .rlib files were built with a different rustc version/configuration.
# Building from source ensures the std library matches our rustc exactly.
#
# Linker wrapper scripts:
# -----------------------
# This element creates wrapper scripts for the MinGW GCC that add:
#   - -static-libgcc: Statically link libgcc to avoid DLL dependency
#   - -fno-stack-protector: Disable SSP (requires unavailable symbols)
#
# Usage:
# ------
# After building this element, you can compile Rust for Windows:
#
#   build-depends:
#   - toolchains/rust-mingw-i686.bst
#
#   Then: cargo build --target i686-pc-windows-gnu
#
# Output: Rustlib at /usr/lib/rustlib/i686-pc-windows-gnu
#
# Source: Rust 1.92.0 source distribution
#
kind: manual

build-depends:
# Rust compiler from freedesktop-sdk
- freedesktop-sdk.bst:components/rust.bst
# Python is required by Rust's x.py build system
- freedesktop-sdk.bst:components/python3-minimal.bst
# CMake and Ninja for building LLVM components
- freedesktop-sdk.bst:components/cmake-stage1.bst
- freedesktop-sdk.bst:components/ninja.bst
# LLVM for the Rust compiler
- freedesktop-sdk.bst:components/llvm.bst
# Complete MinGW-w64 toolchain (provides the cross-linker)
- toolchains/mingw/mingw-w64-i686.bst

depends:
# Runtime dependency on MinGW toolchain (for linking user programs)
- toolchains/mingw/mingw-w64-i686.bst

variables:
  # Rust target triple for Windows 32-bit with MinGW
  rust-target: "i686-pc-windows-gnu"
  # MinGW target triple
  mingw-target: "i686-w64-mingw32"
  # Path to MinGW toolchain
  mingw-prefix: "%{prefix}/mingw-w64/%{mingw-target}"

# MAXJOBS should not affect cache key
environment-nocache:
- MAXJOBS

environment:
  # Parallel build jobs
  MAXJOBS: '%{max-jobs}'
  # Add MinGW tools to PATH so dlltool, ar, etc. can be found by Rust build
  PATH: "%{mingw-prefix}/bin:/usr/bin:/bin"

config:
  configure-commands:
  # Create a wrapper script for GCC that adds required flags
  # -static-libgcc: Avoid runtime dependency on libgcc_s_dw2-1.dll
  # -fno-stack-protector: SSP requires symbols not available in MinGW
  - |
    mkdir -p linker-wrapper
    cat > linker-wrapper/%{mingw-target}-gcc <<EOF
    #!/bin/sh
    exec %{mingw-prefix}/bin/%{mingw-target}-gcc -static-libgcc -fno-stack-protector "\$@"
    EOF
    chmod +x linker-wrapper/%{mingw-target}-gcc

  # Also create wrapper for g++ to be consistent
  - |
    cat > linker-wrapper/%{mingw-target}-g++ <<EOF
    #!/bin/sh
    exec %{mingw-prefix}/bin/%{mingw-target}-g++ -static-libgcc -fno-stack-protector "\$@"
    EOF
    chmod +x linker-wrapper/%{mingw-target}-g++

  # Generate config.toml for Rust's x.py build system
  - |
    WRAPPER_DIR="$(pwd)/linker-wrapper"
    cat <<EOF >config.toml
    [llvm]
    # Use system LLVM instead of downloading
    download-ci-llvm = false
    link-shared = true

    [build]
    # Build on Linux x86_64
    build = "x86_64-unknown-linux-gnu"
    host = ["x86_64-unknown-linux-gnu"]
    # Cross-compile std for Windows i686
    target = ["%{rust-target}"]
    # Use system Rust toolchain
    cargo = "/usr/bin/cargo"
    rustc = "/usr/bin/rustc"
    # Don't build documentation
    docs = false
    # Don't fetch submodules (we vendor everything)
    submodules = false
    python = "/usr/bin/python3"
    locked-deps = true
    vendor = true
    verbose = 1
    # Don't build rustc, just the std library
    extended = false

    [install]
    prefix = "%{prefix}"
    sysconfdir = "%{sysconfdir}"
    libdir = "%{indep-libdir}"

    [rust]
    optimize = true
    channel = "stable"
    # Include debug info in std library
    debuginfo-level-std = 1

    [target.x86_64-unknown-linux-gnu]
    # Use system LLVM
    llvm-config = "/usr/bin/llvm-config"

    [target.%{rust-target}]
    # Use our wrapper scripts that add -static-libgcc and -fno-stack-protector
    cc = "${WRAPPER_DIR}/%{mingw-target}-gcc"
    cxx = "${WRAPPER_DIR}/%{mingw-target}-g++"
    ar = "%{mingw-prefix}/bin/%{mingw-target}-ar"
    ranlib = "%{mingw-prefix}/bin/%{mingw-target}-ranlib"
    linker = "${WRAPPER_DIR}/%{mingw-target}-gcc"
    EOF

  build-commands:
  # Build only the standard library for the target (not the full compiler)
  # Stage 1 is sufficient - we just need the std library artifacts
  - |
    python3 x.py build --stage 1 library --target %{rust-target} -j${MAXJOBS}

  install-commands:
  # Install just the target's rustlib directory
  # This contains the compiled std library that rustc will use for cross-compilation
  - |
    RUSTLIB_SRC="build/x86_64-unknown-linux-gnu/stage1/lib/rustlib/%{rust-target}"
    RUSTLIB_DEST="%{install-root}%{indep-libdir}/rustlib/%{rust-target}"

    if [ -d "${RUSTLIB_SRC}" ]; then
      mkdir -p "%{install-root}%{indep-libdir}/rustlib"
      cp -a "${RUSTLIB_SRC}" "${RUSTLIB_DEST}"
    else
      echo "ERROR: Rustlib directory not found at ${RUSTLIB_SRC}"
      find build -name "rustlib" -type d 2>/dev/null || true
      exit 1
    fi

# Mark the rustlib directory as a development artifact
public:
  bst:
    split-rules:
      devel:
        (>):
        - '%{indep-libdir}/rustlib/%{rust-target}'
        - '%{indep-libdir}/rustlib/%{rust-target}/**'

sources:
# Rust source distribution
- kind: tar
  url: tar_https:static.rust-lang.org/dist/rustc-1.92.0-src.tar.xz
  ref: ebee170bfe4c4dfc59521a101de651e5534f4dae889756a5c97ca9ea40d0c307
