# List available recipes
default:
    @just --list

# Build the wine prefix tarball with the default (Proton-GE) input
build:
    nix build .#prefix

# Build the wine prefix tarball for a specific GE-Proton version
# e.g. `just build-version GE-Proton10-1`
build-version version:
    nix build .#prefix --override-input proton \
        "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/{{version}}/{{version}}.tar.gz"

# Build against an arbitrary Proton tarball/path (UMU-Proton, CachyOS, Valve, ...)
build-with url:
    nix build .#prefix --override-input proton "{{url}}"

# Build a specific flake output (winetricks, winetricksCache, protonFhs, trainer-monitor, wine-prefix, prefix)
build-output name:
    nix build .#{{name}}

# Generate a GitHub Actions build matrix for a range of GE-Proton versions
matrix start end *args:
    ./scripts/generate-proton-matrix.py {{start}} {{end}} {{args}}

# List release entries recorded in docs/releases.json
releases-list *args:
    ./scripts/publish-release-metadata.py list {{args}}

# Add/update a release entry, e.g. `just releases-add GE-Proton9-20 --tarball result/*.tar.gz`
releases-add version *args:
    ./scripts/publish-release-metadata.py add {{version}} {{args}}

# Remove a release entry
releases-remove version *args:
    ./scripts/publish-release-metadata.py remove {{version}} {{args}}

# Sync docs/releases.json from GitHub Releases (requires `gh` CLI)
releases-sync *args:
    ./scripts/publish-release-metadata.py sync --from-github {{args}}

# Format all Nix files
fmt:
    nixpkgs-fmt .

# Check Nix formatting without writing changes
fmt-check:
    nixpkgs-fmt --check .

# Evaluate the flake and run its checks
check:
    nix flake check

# Enter the development shell
dev:
    nix develop

# Remove local build results
clean:
    rm -rf result result-*
