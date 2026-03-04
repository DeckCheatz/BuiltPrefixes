# Build Infrastructure

This document describes the build automation and CI/CD infrastructure for BuiltPrefixes.

## BuildStream Configuration

### project.conf

The main BuildStream configuration defines:

**Minimum version:** BuildStream 2.5

**Options:**
```yaml
options:
  target_arch:
    type: arch
    description: Target architecture
    values:
    - x86_64
    - i686
```

**Key variables:**
- `prefix-root`: Wine prefix location (`%{install-root}/pfx`)
- `proton-root`: Proton installation path (`/proton`)

**Environment:**
```yaml
environment:
  WINEPREFIX: "%{prefix-root}"
  WINE: "%{proton-root}/files/bin/wine"
  WINEARCH: win64
  DISPLAY: ":99"
  STEAM_COMPAT_DATA_PATH: "%{prefix-root}"
  STEAM_COMPAT_CLIENT_INSTALL_PATH: "%{proton-root}"
  MAXJOBS: "%{max-jobs}"
```

### Plugins

**Junction plugins (buildstream-plugins-community):**
- `cargo` - Rust cargo build element
- `cargo2` - Enhanced cargo source with vendored dependencies
- `git_repo` - Git repository source

**Pip plugins (buildstream-plugins):**
- `autotools` - GNU Autotools build element
- `git` - Git source
- `patch` - Patch source

### Junctions

**freedesktop-sdk.bst:**
- Source: gitlab.freedesktop.org
- Tracks: `freedesktop-sdk-25.08.*` releases
- Provides base OS libraries, runtime, and build tools

Configuration for i686 builds:
```yaml
config:
  options:
    build_arch: x86_64  # Use x86_64 for bootstrap even on i686 targets
```

## Source Aliases

Defined in `include/_private/aliases.yml`, source aliases provide:

- Transparent mirroring support
- Shorter, cleaner source URLs
- Centralized URL management

**Categories:**

| Prefix | Example | Description |
|--------|---------|-------------|
| `github:` | `github:user/repo.git` | GitHub repositories |
| `gitlab:` | `gitlab:group/project.git` | GitLab.com repositories |
| `gnome_gitlab:` | `gnome_gitlab:GNOME/gtk.git` | GNOME GitLab |
| `freedesktop_gitlab:` | `freedesktop_gitlab:mesa/mesa.git` | Freedesktop GitLab |
| `tar_https:` | `tar_https:example.com/file.tar.gz` | HTTPS downloads |
| `crates:` | `crates:crate-name/version/download` | Rust crates.io |

## Local Development

### Justfile Commands

The `Justfile` provides task automation:

```bash
# Building
just build                      # Default Proton-GE version
just build-version VERSION      # Specific version

# Artifacts
just checkout [element]         # Extract to checkout/

# Source management
just track [element]            # Update source refs

# Configuration
just update-config VERSION      # Update Proton-GE version
just get-checksum VERSION       # Get SHA256 hash

# CI helpers
just generate-matrix START END  # GitHub Actions matrix

# Status
just status                     # Project overview
```

### Nix Development Environment

`flake.nix` provides a reproducible development environment with:

- BuildStream and plugins
- Python dependencies
- Build utilities

```bash
nix develop  # Enter development shell
```

## GitHub Actions CI/CD

### build-prefix.yml

Multi-version build workflow with matrix strategy.

**Trigger:** Manual (`workflow_dispatch`)

**Inputs:**
- `start_version`: First Proton-GE version (e.g., `GE-Proton9-1`)
- `end_version`: Last Proton-GE version (e.g., `GE-Proton9-20`)
- `verify_versions`: Check versions exist on GitHub (default: true)

**Jobs:**

1. **generate-matrix**
   - Runs `scripts/generate-proton-matrix.py`
   - Outputs JSON matrix for parallel builds

2. **build** (matrix strategy)
   - Runs for each version in matrix
   - Installs BuildStream and dependencies
   - Manages cache by version
   - Builds `deploy/prefix.bst`
   - Creates GitHub release

3. **update-metadata**
   - Syncs release metadata
   - Publishes to GitHub Pages

**Caching:**

BuildStream cache is stored per Proton-GE version:
```yaml
- uses: actions/cache@v4
  with:
    path: ~/.cache/buildstream
    key: bst-${{ matrix.version }}-${{ hashFiles('elements/**') }}
```

### build-single.yml

Single version build workflow.

**Trigger:** Manual (`workflow_dispatch`)

**Inputs:**
- `version`: Proton-GE version to build

**Steps:**
1. Update Proton-GE configuration
2. Build prefix
3. Checkout artifacts
4. Create GitHub release

### pages.yml

GitHub Pages publishing for release metadata.

**Trigger:** Push to main, manual

**Publishes:**
- `docs/` directory to GitHub Pages
- Release metadata JSON

## Scripts

### update-proton-config.py

Updates Proton-GE version configuration.

```bash
python scripts/update-proton-config.py GE-Proton9-20
```

**Actions:**
1. Constructs download URL from version string
2. Downloads release to calculate SHA256
3. Updates `include/proton-ge-config.yml`

**Output format:**
```yaml
variables:
  proton_ge_version: "GE-Proton9-20"
  proton_ge_hash: "8c3599e26e5a5002e1b3f1211b0ac56bfddd6eb2c4dcbae7d81027182ed36c89"
  proton_ge_url: "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton9-20/GE-Proton9-20.tar.gz"
```

### generate-proton-matrix.py

Generates GitHub Actions build matrix.

```bash
python scripts/generate-proton-matrix.py GE-Proton9-1 GE-Proton9-20 --verify
```

**Arguments:**
- `start`: First version in range
- `end`: Last version in range
- `--verify`: Check versions exist on GitHub

**Output:**
```json
{
  "include": [
    {"version": "GE-Proton9-1"},
    {"version": "GE-Proton9-2"},
    ...
    {"version": "GE-Proton9-20"}
  ]
}
```

### publish-release-metadata.py

Manages release metadata for GitHub Pages.

```bash
python scripts/publish-release-metadata.py sync   # Sync from releases
python scripts/publish-release-metadata.py add VERSION  # Add version
```

## BuildStream Cache Management

### Local Cache

Default location: `~/.cache/buildstream/`

```bash
# Clear all caches
bst artifact delete '*'

# Clear specific element
bst artifact delete deploy/prefix.bst
```

### CI Cache Strategy

The CI uses version-specific cache keys:
- **Key:** `bst-{version}-{elements-hash}`
- **Restore keys:** `bst-{version}-`, `bst-`

This ensures:
- Version-specific caches don't interfere
- Element changes invalidate caches
- Fallback to older caches for faster builds

## Debugging Builds

### Shell Access

```bash
# Enter build environment
bst shell deploy/prefix.bst

# Enter with staged dependencies
bst shell --build deploy/prefix.bst
```

### Build Logs

```bash
# Verbose build
bst --verbose build deploy/prefix.bst

# Show element configuration
bst show deploy/prefix.bst
```

### Dependency Graph

```bash
# Show dependencies
bst show --deps all deploy/prefix.bst

# Show build order
bst show --deps build deploy/prefix.bst
```
