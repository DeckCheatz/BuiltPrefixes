# Toolchain Documentation

This document describes the cross-compilation toolchains available in BuiltPrefixes.

## MinGW-w64 i686 Toolchain

The MinGW-w64 toolchain provides a complete GCC-based cross-compiler for building Windows 32-bit (i686) applications on Linux.

### Components

#### binutils-i686.bst

GNU Binutils 2.44 for the `i686-w64-mingw32` target.

**Provides:**
- `i686-w64-mingw32-as` - Assembler
- `i686-w64-mingw32-ld` - Linker
- `i686-w64-mingw32-ar` - Archive tool
- `i686-w64-mingw32-objcopy`, `objdump`, `strip`, etc.

**Installation prefix:** `/usr/mingw-w64/i686-w64-mingw32`

#### mingw-w64-headers-i686.bst

Windows API header files from mingw-w64.

**Features:**
- Complete Windows SDK headers
- IDL support
- Secure API extensions

#### gcc-core-i686.bst

Stage 1 GCC compiler (C language only).

This minimal compiler is required to bootstrap the MinGW-w64 C Runtime before the full GCC can be built.

**Configuration:**
- Languages: C, LTO only
- No shared libraries
- No threading support
- Exception handling: DWARF2

#### mingw-w64-crt-i686.bst

The MinGW-w64 C Runtime library implements the C standard library for Windows.

**Configuration:**
- 32-bit libraries only (`--enable-lib32 --disable-lib64`)
- Stack protection disabled (MinGW SSP requires unavailable symbols)
- Wildcard expansion enabled

**Build flags:**
```
CFLAGS="-O2 -g -fno-stack-protector"
```

#### winpthreads-i686.bst

POSIX threads implementation for Windows, enabling `pthread_*` APIs.

**Builds:**
- Static library: `libpthread.a`
- Shared library: `libwinpthread-1.dll`

**Note:** Linux-specific linker flags (`-z relro`, `-z now`) are disabled as MinGW's `ld` doesn't support them.

#### gcc-i686.bst

Full GCC compiler with C++ and LTO support.

**Configuration:**
- Languages: C, C++, LTO
- Thread model: POSIX (via winpthreads)
- Exception handling: DWARF2 (required for Rust compatibility)
- Shared and static library support

**Sources:**
- GCC 14.3.0
- GMP 6.3.0
- MPFR 4.2.2
- MPC 1.3.1
- ISL 0.27

**Convenience symlinks:**
- `i686-w64-mingw32-gcc` → `mingw32-gcc`
- `i686-w64-mingw32-g++` → `mingw32-g++`

#### mingw-w64-i686.bst

Stack element that aggregates all MinGW-w64 components. Use this as a single dependency to get the complete toolchain.

### Build Order

The toolchain must be built in a specific order due to circular dependencies:

1. **binutils** - No dependencies on other MinGW components
2. **mingw-w64-headers** - Requires binutils
3. **gcc-core** - Stage 1 compiler, requires headers
4. **mingw-w64-crt** - Requires gcc-core to compile
5. **winpthreads** - Requires CRT and gcc-core
6. **gcc** - Full compiler, requires CRT and winpthreads

## Rust Windows i686 Toolchain

### rust-mingw-i686.bst

Builds the Rust standard library for the `i686-pc-windows-gnu` target from source.

**Why build from source?**

Pre-built Rust target libraries from rustup have different metadata than the freedesktop-sdk's rustc compiler, causing linking failures. Building from source ensures compatibility.

**Build process:**

1. Creates linker wrapper scripts that:
   - Use static libgcc (`-static-libgcc`)
   - Disable stack protection (`-fno-stack-protector`)

2. Generates `config.toml` for Rust's x.py build system:
   - Host: `x86_64-unknown-linux-gnu`
   - Target: `i686-pc-windows-gnu`
   - Uses system LLVM

3. Builds Stage 1 standard library only (not the full compiler)

4. Installs rustlib to `/usr/lib/rustlib/i686-pc-windows-gnu`

**Dependencies:**
- freedesktop-sdk Rust compiler
- MinGW-w64 i686 toolchain
- LLVM, CMake, Ninja, Python 3

### rust-windows-i686-stack.bst

Stack element that provides everything needed for Rust Windows i686 cross-compilation:

- freedesktop-sdk Rust compiler
- MinGW-w64 i686 toolchain (runtime dependency)
- Rust standard library for i686-pc-windows-gnu

## Using the Toolchains

### C/C++ Cross-Compilation

```yaml
kind: autotools

build-depends:
- toolchains/mingw/mingw-w64-i686.bst

environment:
  PATH: "/usr/mingw-w64/i686-w64-mingw32/bin:/usr/bin:/bin"
  CC: "i686-w64-mingw32-gcc"
  CXX: "i686-w64-mingw32-g++"

config:
  configure-commands:
  - ./configure --host=i686-w64-mingw32
```

### Rust Cross-Compilation

```yaml
kind: cargo

build-depends:
- toolchains/rust-windows-i686-stack.bst

variables:
  cargo-install-local: >-
    --target=i686-pc-windows-gnu

environment:
  PATH: "/usr/mingw-w64/i686-w64-mingw32/bin:/usr/bin:/bin"
```

## Technical Notes

### Exception Handling

The toolchain uses DWARF2 exception handling (`--with-dwarf2 --disable-sjlj-exceptions`) instead of SJLJ. This is required for Rust compatibility, as Rust expects `_Unwind_Resume` and `_Unwind_RaiseException` symbols rather than the SJLJ variants (`__Unwind_SjLj_*`).

### Stack Protection

Stack Smashing Protection (SSP) is disabled in the CRT and linker wrappers because MinGW's SSP implementation requires symbols (`write`, `_imp__rand_s`) that aren't available in the minimal CRT environment.

### Static libgcc

The Rust linker wrapper uses `-static-libgcc` to avoid runtime dependency on `libgcc_s_dw2-1.dll`.

### Build Parallelization

All elements use `${MAXJOBS}` for parallel builds, which is set from BuildStream's `%{max-jobs}` variable. This is marked in `environment-nocache` to prevent cache invalidation when the job count changes.
