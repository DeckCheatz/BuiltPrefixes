# Rust standard library for i686-pc-windows-gnu target
# Builds the std library from source for compatibility with freedesktop-sdk's rustc
#
# Usage: After including this in your build-depends, you can compile with:
#   cargo build --target i686-pc-windows-gnu
#
kind: manual

build-depends:
- freedesktop-sdk.bst:components/rust.bst
- freedesktop-sdk.bst:components/python3-minimal.bst
- freedesktop-sdk.bst:components/cmake-stage1.bst
- freedesktop-sdk.bst:components/ninja.bst
- freedesktop-sdk.bst:components/llvm.bst
- toolchains/mingw/mingw-w64-i686.bst

depends:
- toolchains/mingw/mingw-w64-i686.bst

variables:
  rust-target: "i686-pc-windows-gnu"
  mingw-target: "i686-w64-mingw32"
  mingw-prefix: "%{prefix}/mingw-w64/%{mingw-target}"

environment-nocache:
- MAXJOBS

environment:
  MAXJOBS: '%{max-jobs}'
  # Add MinGW tools to PATH so dlltool, ar, etc. can be found
  PATH: "%{mingw-prefix}/bin:/usr/bin:/bin"

config:
  configure-commands:
  # Create a wrapper script that uses static libgcc and disables SSP which has missing symbols
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

  - |
    WRAPPER_DIR="$(pwd)/linker-wrapper"
    cat <<EOF >config.toml
    [llvm]
    download-ci-llvm = false
    link-shared = true

    [build]
    build = "x86_64-unknown-linux-gnu"
    host = ["x86_64-unknown-linux-gnu"]
    target = ["%{rust-target}"]
    cargo = "/usr/bin/cargo"
    rustc = "/usr/bin/rustc"
    docs = false
    submodules = false
    python = "/usr/bin/python3"
    locked-deps = true
    vendor = true
    verbose = 1
    extended = false

    [install]
    prefix = "%{prefix}"
    sysconfdir = "%{sysconfdir}"
    libdir = "%{indep-libdir}"

    [rust]
    optimize = true
    channel = "stable"
    debuginfo-level-std = 1

    [target.x86_64-unknown-linux-gnu]
    llvm-config = "/usr/bin/llvm-config"

    [target.%{rust-target}]
    cc = "${WRAPPER_DIR}/%{mingw-target}-gcc"
    cxx = "${WRAPPER_DIR}/%{mingw-target}-g++"
    ar = "%{mingw-prefix}/bin/%{mingw-target}-ar"
    ranlib = "%{mingw-prefix}/bin/%{mingw-target}-ranlib"
    linker = "${WRAPPER_DIR}/%{mingw-target}-gcc"
    EOF

  build-commands:
  # Build only the standard library for the target
  - |
    python3 x.py build --stage 1 library --target %{rust-target} -j${MAXJOBS}

  install-commands:
  # Install just the target's rustlib directory
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

public:
  bst:
    split-rules:
      devel:
        (>):
        - '%{indep-libdir}/rustlib/%{rust-target}'
        - '%{indep-libdir}/rustlib/%{rust-target}/**'

sources:
- kind: tar
  url: tar_https:static.rust-lang.org/dist/rustc-1.92.0-src.tar.xz
  ref: ebee170bfe4c4dfc59521a101de651e5534f4dae889756a5c97ca9ea40d0c307
