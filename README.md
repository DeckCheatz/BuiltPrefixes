# BuiltPrefixes

A **Nix** build system for creating pre-configured Wine/Proton prefixes, built
reproducibly inside the Nix sandbox and packaged as a `.tgz`.

## Overview

This project takes a **Proton runtime** — [Proton-GE](https://github.com/GloriousEggroll/proton-ge-custom),
[UMU-Proton](https://github.com/Open-Wine-Components/umu-proton),
[CachyOS Proton](https://github.com/CachyOS/proton-cachyos), or Valve's Proton —
and produces a ready-to-use Wine prefix with common Windows components already
installed:

- Initialises the prefix with Proton's bundled Wine (`wineboot`)
- Installs, offline, via winetricks: **SDL**, **VKD3D**, **DXVK 2.3**, **.NET Framework 4.8**
- Cross-compiles [`trainer-monitor`](https://github.com/DeckCheatz/trainer-monitor)
  to Windows 32-bit and installs `trainer-monitor.exe` into the prefix
- Emits the whole prefix as `wine-prefix-<version>.tar.gz`, alongside a
  `wine-prefix-metadata.json` recording the source Proton, installed
  winetricks verb versions, and the building flake's git revision

Everything runs inside the Nix build sandbox: Proton's Wine executes in a nested
FHS environment (`buildFHSEnv`), and every download (Proton, winetricks packages)
is a pinned, hash-checked input, so builds are hermetic and reproducible.

## Requirements

- Nix with flakes enabled (`experimental-features = nix-command flakes`)
- Linux with unprivileged user namespaces available (for the nested FHS sandbox)

## Quick Start

```bash
# Build the prefix with the default Proton (Proton-GE) -> result/wine-prefix-<ver>.tar.gz
nix build .#prefix

# Inspect the tarball
tar tzf result/wine-prefix-*.tar.gz | head

# Use it
mkdir -p ~/.wine-ge && tar -xzf result/wine-prefix-*.tar.gz -C ~/.wine-ge
```

### Selecting the Proton distribution / version

The Proton runtime is **not** stored in a config file — it is the `proton` flake
input. Override it per build with `--override-input proton <tarball-or-path>`.
The build auto-detects each distribution's layout (`files/` vs `dist/`, and
whether a 32-bit `wine` is present), so any Proton bundle works:

```bash
# Proton-GE (a specific version)
nix build .#prefix --override-input proton \
  https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton10-1/GE-Proton10-1.tar.gz

# UMU-Proton
nix build .#prefix --override-input proton \
  https://github.com/Open-Wine-Components/umu-proton/releases/download/UMU-Proton-10.0-4/UMU-Proton-10.0-4.tar.gz

# CachyOS Proton
nix build .#prefix --override-input proton \
  https://github.com/CachyOS/proton-cachyos/releases/download/cachyos-11.0-20260703-slr/proton-cachyos-11.0-20260703-slr-x86_64.tar.xz

# Valve Proton (no public tarball; point at an extracted Proton directory)
nix build .#prefix --override-input proton \
  "path:$HOME/.steam/steam/steamapps/common/Proton 9.0 (Beta)"
```

To change the default, edit the `proton` input URL in `flake.nix` and run
`nix flake lock`.

### Using Just

A `Justfile` wraps the common commands (`just build`, `just build-version
GE-Proton10-1`, `just matrix ...`, `just releases-list`, `just fmt`, `just
check`). Run `just` or `just --list` to see all recipes.

## Flake outputs

| Attribute | Description |
|-----------|-------------|
| `packages.prefix` (`default`) | The final `wine-prefix-<version>.tar.gz` |
| `packages.wine-prefix` | The built prefix as a plain directory (for inspection) |
| `packages.trainer-monitor` | `trainer-monitor.exe` cross-compiled to `i686-pc-windows-gnu` |
| `packages.winetricks` | Patched winetricks used by the build |
| `packages.winetricksCache` | The offline winetricks download cache |
| `packages.protonFhs` | The FHS environment Proton's Wine runs inside |
| `devShells.default` | Shell with Nix, `nixpkgs-fmt`, `just`, and Python for the CI scripts |

## Project Structure

```
BuiltPrefixes/
├── flake.nix                 # Inputs (nixpkgs, proton-ge, trainer-monitor) + packages
├── Justfile                  # Local wrappers for the Nix/CI commands
├── nix/
│   ├── winetricks.nix        # Patched winetricks (pinned git + patches/)
│   ├── winetricks-cache.nix  # Offline download cache (fetchurl FODs)
│   ├── trainer-monitor.nix   # Rust cross-compile -> i686-pc-windows-gnu
│   ├── proton-fhs.nix        # buildFHSEnv that runs Proton's Wine + Xvfb
│   └── wine-prefix.nix       # Core sandbox build (wineboot + winetricks + install exe)
├── patches/winetricks/       # Offline/ownership fixes applied to winetricks
├── scripts/                  # CI helpers (matrix generation, release metadata)
├── docs/                     # Published release metadata
└── .github/workflows/        # CI: build a version, matrix builds, pages
```

## How the build works

1. `winetricks-cache.nix` fetches the Windows runtime installers (SDL, DXVK,
   VKD3D, .NET, 7-Zip) as hash-pinned `fetchurl` derivations and lays them out
   in winetricks' cache layout.
2. `trainer-monitor.nix` cross-compiles the Rust watchdog to a Windows `.exe`
   via `pkgsCross.mingw32`.
3. `wine-prefix.nix` runs, inside `proton-fhs`, the same sequence the project
   has always used: `wineboot -i`, then
   `winetricks -q sdl vkd3d dxvk2030 dotnet48`, then installs
   `trainer-monitor.exe`. A headless `Xvfb` provides the display the .NET
   installer needs. The finished prefix is copied to the output, alongside a
   `wine-prefix-metadata.json` written at eval time (no shell templating), e.g.:

   ```json
   {
     "proton": {
       "version": "GE-Proton9-12",
       "narHash": "sha256-2/vxX5AT1qQ50jBrQkZIzlmzkOAX+qzINEeD3Lo1f40=",
       "lastModifiedDate": "20240831222404"
     },
     "winetricksVerbs": {
       "sdl": "1.2.15",
       "vkd3d": "3.0b",
       "dxvk2030": "2.3",
       "dotnet48": "4.8"
     },
     "flake": { "rev": "ad73a390c0a607e3065d39eb0d1c6a1bb0280b13-dirty" }
   }
   ```

   `proton.narHash` identifies the exact Proton tarball that was fetched
   (accurate even when `proton` was overridden via `--override-input`, since
   that never changes the bundled `version` file's own self-reported string).
   `flake.rev` is `self.rev`, or `self.dirtyRev` (suffixed `-dirty`) for an
   uncommitted tree.
4. `flake.nix` tars that directory (including `wine-prefix-metadata.json`)
   reproducibly into `wine-prefix-<version>.tar.gz`.

## CI/CD

GitHub Actions workflows build prefixes with Nix and publish them as releases:

- **build-single.yml** — build one Proton-GE version (manual dispatch)
- **build-matrix.yml** — build a range of versions in parallel
- **build-version.yml** — reusable build job (`nix build .#prefix
  --override-input proton-ge <url>`), release upload, and metadata update
- **pages.yml** — publishes release metadata to GitHub Pages

## License

See individual component licenses.
