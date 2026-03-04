# BuiltPrefixes

A BuildStream-based build system for creating Wine/Proton prefixes with cross-compilation support for Windows targets.

## Overview

This project builds upon the Freedesktop SDK to:

- Create pre-configured Wine prefixes with Proton-GE runtime
- Build complete MinGW-w64 cross-compilation toolchains for Windows targets
- Provide Rust cross-compilation support targeting Windows 32-bit (i686-pc-windows-gnu)
- Install and configure Wine components (winetricks, DirectX libraries, runtimes)
- Automate builds via GitHub Actions with version matrix generation

## Requirements

- BuildStream >= 2.5
- bubblewrap (for sandboxed builds)
- Python 3.x

## Quick Start

```bash
# Build the Wine prefix with default Proton-GE version
just build

# Build with a specific Proton-GE version
just build-version GE-Proton9-20

# Extract built artifacts
just checkout deploy/prefix.bst
```

## Project Structure

```
BuiltPrefixes/
├── elements/                          # BuildStream element definitions
│   ├── components/                    # Application components
│   ├── toolchains/                    # Compiler toolchains
│   │   └── mingw/                     # MinGW-w64 cross-compiler stack
│   ├── deploy/                        # Deployment elements
│   └── plugins/                       # Plugin definitions
├── include/                           # Shared configuration includes
│   ├── _private/
│   │   └── aliases.yml                # URL aliases for sources
│   └── proton-ge-config.yml           # Proton-GE version configuration
├── patches/                           # Patch files
├── scripts/                           # Build automation scripts
├── .github/workflows/                 # GitHub Actions CI/CD
├── project.conf                       # Main BuildStream configuration
├── Justfile                           # Task automation
└── flake.nix                          # Nix development environment
```

## Elements

### Main Build Target

**deploy/prefix.bst** - Creates a complete Wine prefix with Proton-GE runtime and all dependencies.

### Components

| Element | Description |
|---------|-------------|
| `components/proton-ge-source.bst` | Downloads Proton-GE release archive |
| `components/trainer-monitor.bst` | Rust application targeting Windows i686 |
| `components/winetricks.bst` | Wine tricks helper tool |
| `components/winetricks-packages.bst` | Windows runtime dependencies (7zip, .NET, DXVK, VKD3D, SDL) |

### Toolchains

#### MinGW-w64 i686 Stack

A complete cross-compilation toolkit for building Windows 32-bit applications on Linux.

| Element | Description |
|---------|-------------|
| `toolchains/mingw/binutils-i686.bst` | GNU Binutils for i686-w64-mingw32 |
| `toolchains/mingw/mingw-w64-headers-i686.bst` | Windows API headers |
| `toolchains/mingw/gcc-core-i686.bst` | GCC Stage 1 (C only, for bootstrapping) |
| `toolchains/mingw/mingw-w64-crt-i686.bst` | C Runtime library |
| `toolchains/mingw/winpthreads-i686.bst` | POSIX threads implementation |
| `toolchains/mingw/gcc-i686.bst` | Full GCC (C, C++, LTO) |
| `toolchains/mingw/mingw-w64-i686.bst` | Stack aggregating all MinGW components |

**Build hierarchy:**

```
mingw-w64-i686.bst (stack)
├── binutils-i686.bst
├── mingw-w64-headers-i686.bst
│   └── binutils-i686.bst
├── gcc-core-i686.bst (Stage 1)
│   ├── binutils-i686.bst
│   └── mingw-w64-headers-i686.bst
├── mingw-w64-crt-i686.bst
│   ├── mingw-w64-headers-i686.bst
│   └── gcc-core-i686.bst
├── winpthreads-i686.bst
│   ├── mingw-w64-crt-i686.bst
│   └── gcc-core-i686.bst
└── gcc-i686.bst (Full compiler)
    ├── mingw-w64-crt-i686.bst
    └── winpthreads-i686.bst
```

#### Rust Windows i686 Stack

| Element | Description |
|---------|-------------|
| `toolchains/rust-mingw-i686.bst` | Rust std library for i686-pc-windows-gnu |
| `toolchains/rust-windows-i686-stack.bst` | Complete Rust cross-compilation stack |

## Configuration

### Project Options

- `target_arch`: Target architecture (x86_64 or i686)

### Environment Variables

The build environment configures:

- `WINEPREFIX`, `WINE`, `WINEARCH`: Wine configuration
- `STEAM_COMPAT_*`: Steam Proton compatibility paths
- `MAXJOBS`: Build parallelization

### Proton-GE Version

Update the Proton-GE version:

```bash
just update-config GE-Proton9-20
```

This updates `include/proton-ge-config.yml` with the version and SHA256 checksum.

## Build Commands

| Command | Description |
|---------|-------------|
| `just build` | Build with default Proton-GE version |
| `just build-version VERSION` | Build specific Proton-GE version |
| `just checkout [element]` | Extract built artifacts |
| `just track [element]` | Track source updates |
| `just update-config VERSION` | Update Proton-GE version/hash |
| `just get-checksum VERSION` | Calculate SHA256 for version |
| `just generate-matrix START END` | Create GitHub Actions matrix |
| `just status` | Show project status |

## Cross-Compiling Rust for Windows

To build a Rust application for Windows i686:

1. Add the toolchain stack to your element's `build-depends`:

```yaml
build-depends:
- toolchains/rust-windows-i686-stack.bst
```

2. Configure cargo to target Windows:

```yaml
variables:
  cargo-install-local: >-
    --target=i686-pc-windows-gnu

environment:
  PATH: "/usr/mingw-w64/i686-w64-mingw32/bin:/usr/bin:/bin"
```

See `elements/components/trainer-monitor.bst` for a complete example.

## CI/CD

### GitHub Actions Workflows

- **build-prefix.yml**: Multi-version build with matrix generation
- **build-single.yml**: Single Proton-GE version build
- **pages.yml**: Publishes release metadata to GitHub Pages

### Build Matrix

Generate a build matrix for multiple Proton-GE versions:

```bash
just generate-matrix GE-Proton9-1 GE-Proton9-20
```

## Plugins

The project uses:

- **buildstream-plugins-community**: cargo, cargo2, git_repo sources
- **buildstream-plugins**: autotools, git, patch sources

## License

See individual component licenses.
