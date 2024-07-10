# Justfile for BuiltPrefixes - Docker Wine Prefix Builder
# https://github.com/casey/just

# Default recipe to display help
default:
    @just --list

# Variables
export PARALLEL_BUILDS := env_var_or_default("PARALLEL_BUILDS", "2")
export BUILD_TIMEOUT := env_var_or_default("BUILD_TIMEOUT", "3600")

# Development commands
# ===================

# Show project status and Docker info
info:
    @echo "BuiltPrefixes - Docker Wine Prefix Builder"
    @echo "==========================================="
    @echo ""
    docker --version || echo "Docker not installed"
    @echo ""
    @echo "Available Docker images:"
    docker images | grep wine-prefix-builder || echo "No wine-prefix-builder image found"

# List available Proton-GE releases
list-releases vendor="proton-ge" count="10":
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Use the common fetch script for consistent release information
    ./scripts/fetch-proton-releases.sh "{{vendor}}" human "{{count}}"
    
    echo ""
    echo "Usage examples:"
    echo "  just build-ge GE-Proton10-10     # Build specific Proton-GE version"
    echo "  just build-ge-latest             # Build latest Proton-GE version"
    echo "  just list-releases proton-ge 5   # Show 5 latest Proton-GE releases"

# Update Docker image
update:
    just build-docker-image

# Clean up build artifacts and Docker cache
clean:
    rm -rf artifacts/ .cache/ output/
    docker system prune -f || true
    echo "✓ Cleaned build artifacts and Docker cache"

# Building commands
# =================

# Build Docker image for Wine prefix creation
build-docker-image:
    docker build -t wine-prefix-builder .

# Build generic Wine prefix with Proton-GE using Docker
build-ge version="GE-Proton10-10":
    #!/usr/bin/env bash
    set -euo pipefail
    
    URL="https://github.com/GloriousEggroll/proton-ge-custom/archive/{{version}}.tar.gz"
    OUTPUT_DIR="./output"
    
    echo "Building Wine prefix with Proton-GE {{version}} using Docker..."
    mkdir -p "$OUTPUT_DIR"
    
    docker run --rm --privileged \
        -v "$PWD/docker-scripts:/scripts:ro" \
        -v "$OUTPUT_DIR:/output" \
        wine-prefix-builder \
        /scripts/build-prefix.sh "$URL" /output


# Build with the absolute latest Proton-GE release using Docker
build-ge-latest:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "🔍 Fetching latest Proton-GE release..."
    LATEST_URL=$(./scripts/fetch-proton-releases.sh proton-ge urls 1 | cut -d'|' -f3)
    OUTPUT_DIR="./output"
    
    echo "🏗️  Building with latest Proton-GE using Docker..."
    echo "Source URL: $LATEST_URL"
    mkdir -p "$OUTPUT_DIR"
    
    docker run --rm --privileged \
        -v "$PWD/docker-scripts:/scripts:ro" \
        -v "$OUTPUT_DIR:/output" \
        wine-prefix-builder \
        /scripts/build-prefix.sh "$LATEST_URL" /output


# Testing commands
# ================

# Test Docker setup and basic functionality
test-basic:
    @echo "Testing Docker setup..."
    docker --version
    @echo "Testing fetch script..."
    ./scripts/fetch-proton-releases.sh proton-ge versions 1

# Validate that all scripts are executable
test-scripts:
    @echo "Checking script permissions..."
    @test -x scripts/fetch-proton-releases.sh || (echo "❌ fetch-proton-releases.sh not executable" && exit 1)
    @test -x docker-scripts/build-prefix.sh || (echo "❌ build-prefix.sh not executable" && exit 1)
    @echo "✓ All scripts are executable"

# Test the fetch script with different output formats
test-fetch-script:
    @echo "Testing fetch script output formats..."
    @echo ""
    @echo "🔍 Testing versions format:"
    @./scripts/fetch-proton-releases.sh proton-ge versions 3
    @echo ""
    @echo "🔗 Testing URLs format (first line only):"
    @./scripts/fetch-proton-releases.sh valve urls 1
    @echo ""
    @echo "✓ Fetch script test completed"

# Test Docker setup
test-docker:
    @echo "Testing Docker setup..."
    docker --version
    @echo "Building Docker image..."
    just build-docker-image
    @echo "✓ Docker test completed"

# Installation and deployment
# ===========================

# Install a built prefix to the home directory
install prefix_path="./output" target_dir="$HOME/.wine-prefixes/generic":
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Find the most recent prefix directory
    if [[ -d "{{prefix_path}}" ]]; then
        LATEST_PREFIX=$(find "{{prefix_path}}" -maxdepth 1 -type d -name "*-*" | sort | tail -1)
        if [[ -n "$LATEST_PREFIX" && -f "$LATEST_PREFIX/scripts/install-prefix.sh" ]]; then
            echo "Installing prefix from $LATEST_PREFIX to {{target_dir}}..."
            "$LATEST_PREFIX/scripts/install-prefix.sh" "{{target_dir}}"
        else
            echo "❌ No valid prefix found in {{prefix_path}}"
            echo "Build a prefix first with: just build-ge or just build-valve"
            exit 1
        fi
    else
        echo "❌ Output directory {{prefix_path}} not found"
        echo "Build a prefix first with: just build-ge or just build-valve"
        exit 1
    fi

# Run an application with the installed prefix
run-app app_path target_dir="$HOME/.wine-prefixes/generic":
    @if [ -d "{{target_dir}}" ] && [ -x "{{target_dir}}/run-app.sh" ]; then \
        "{{target_dir}}/run-app.sh" "{{app_path}}"; \
    else \
        echo "❌ No installed prefix found at {{target_dir}}"; \
        echo "Install a prefix first with: just install"; \
        exit 1; \
    fi

# Configure Wine settings for installed prefix
winecfg target_dir="$HOME/.wine-prefixes/generic":
    @just run-app winecfg "{{target_dir}}"

# Archive a built prefix to a compressed file
archive-prefix prefix_path="./output" output_dir="./archives":
    #!/usr/bin/env bash
    set -euo pipefail
    
    # Find the most recent prefix directory
    if [[ ! -d "{{prefix_path}}" ]]; then
        echo "❌ Output directory {{prefix_path}} not found"
        echo "Build a prefix first with: just build-ge or just build-valve"
        exit 1
    fi
    
    ACTUAL_PREFIX=$(find "{{prefix_path}}" -maxdepth 1 -type d -name "*-*" | sort | tail -1)
    if [[ -z "$ACTUAL_PREFIX" ]]; then
        echo "❌ No built prefix found in {{prefix_path}}"
        echo "Build a prefix first with: just build-ge or just build-valve"
        exit 1
    fi
    
    # Extract version info from the prefix
    if [[ -f "$ACTUAL_PREFIX/README.md" ]]; then
        VERSION_INFO=$(grep -E "(Proton Version|Vendor)" "$ACTUAL_PREFIX/README.md" | head -2 | tr '\n' ' ')
        echo "Prefix info: $VERSION_INFO"
    else
        echo "Warning: No version info found in prefix"
    fi
    
    # Create output directory
    mkdir -p "{{output_dir}}"
    
    # Generate archive name with timestamp
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    ARCHIVE_NAME="proton-prefix-${TIMESTAMP}.tar.gz"
    OUTPUT_PATH="{{output_dir}}/${ARCHIVE_NAME}"
    
    echo "Creating archive..."
    echo "  Source: $ACTUAL_PREFIX"
    echo "  Target: $OUTPUT_PATH"
    
    # Create the archive
    tar -czf "$OUTPUT_PATH" -C "$(dirname "$ACTUAL_PREFIX")" "$(basename "$ACTUAL_PREFIX")"
    
    # Get file size
    FILE_SIZE=$(du -h "$OUTPUT_PATH" | cut -f1)
    
    echo ""
    echo "✅ Archive created successfully!"
    echo "📁 File: $OUTPUT_PATH"
    echo "📊 Size: $FILE_SIZE"
    echo ""
    echo "To extract and use:"
    echo "  tar -xzf '$OUTPUT_PATH'"
    echo "  cd '$(basename "$ACTUAL_PREFIX")'"
    echo "  ./scripts/install-prefix.sh"
    
    # Output the file path for scripting
    echo "$OUTPUT_PATH"

# CI/CD commands
# ==============

# Get build arguments for CI (JSON output for easy parsing)
ci-get-build-args vendor="both" count="3":
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "{"
    echo '  "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",'
    echo '  "releases": {'
    
    if [[ "{{vendor}}" == "both" || "{{vendor}}" == "proton-ge" ]]; then
        echo '    "proton-ge": ['
        ./scripts/fetch-proton-releases.sh proton-ge build-args {{count}} | \
        sed 's/^/      "/' | sed 's/$/"/' | sed '$!s/$/,/'
        echo '    ]'
        if [[ "{{vendor}}" == "both" ]]; then
            echo '    ,'
        fi
    fi
    
    if [[ "{{vendor}}" == "both" || "{{vendor}}" == "valve" ]]; then
        echo '    "valve": ['
        ./scripts/fetch-proton-releases.sh valve build-args {{count}} | \
        sed 's/^/      "/' | sed 's/$/"/' | sed '$!s/$/,/'
        echo '    ]'
    fi
    
    echo '  }'
    echo "}"

# Simulate CI build process locally
ci-test:
    @echo "Simulating CI build process..."
    just build-docker-image
    just build-ge-latest
    @echo "✓ CI simulation completed"

# Maintenance commands
# ===================

# Full cleanup including Docker cleanup
deep-clean:
    just clean
    docker system prune -af || true

# Update everything (Docker image, etc.)
update-all:
    just update
    just test-basic

# Prepare for release (build, test)
prepare-release:
    just clean
    just update
    just test-scripts
    just ci-test

# Show project status and information
status:
    @echo "BuiltPrefixes Project Status"
    @echo "=========================="
    @echo ""
    @echo "Repository:"
    @git remote get-url origin 2>/dev/null || echo "  Not a git repository"
    @echo ""
    @echo "Current branch:"
    @git branch --show-current 2>/dev/null || echo "  Unknown"
    @echo ""
    @echo "Latest commit:"
    @git log -1 --oneline 2>/dev/null || echo "  No commits"
    @echo ""
    @echo "Docker status:"
    @docker --version 2>/dev/null || echo "  Docker not available"
    @echo "  Wine prefix builder image:"
    @docker images | grep wine-prefix-builder || echo "    Not built"
    @echo ""
    @echo "Available Proton releases (latest 3):"
    @./scripts/fetch-proton-releases.sh both human 3 2>/dev/null || echo "  Unable to fetch releases"
    @echo ""
    @echo "Disk usage:"
    @du -sh . 2>/dev/null || echo "  Unable to calculate"

# Documentation and help
# ======================

# Show detailed help with examples
help:
    @echo "BuiltPrefixes - Docker Wine Prefix Builder"
    @echo "=========================================="
    @echo ""
    @echo "This project creates universal Wine prefixes using official Proton releases"
    @echo "that can run any Windows application or game via Docker containers."
    @echo ""
    @echo "Common workflows:"
    @echo ""
    @echo "  1. Development setup:"
    @echo "     just build-docker-image     # Build Docker image"
    @echo "     just info                   # Show current configuration"
    @echo "     just list-releases          # List available Proton releases"
    @echo ""
    @echo "  2. Build a generic prefix:"
    @echo "     just build-ge-latest        # Build with absolute latest Proton-GE"
    @echo "     just build-ge GE-Proton10-9 # Build with specific version"
    @echo ""
    @echo "  3. Install and use:"
    @echo "     just install                # Install built prefix"
    @echo "     just run-app /path/to/game.exe"
    @echo "     just winecfg                # Configure Wine"
    @echo "     just archive-prefix         # Create archive of built prefix"
    @echo ""
    @echo "  4. CI and testing:"
    @echo "     just ci-test                # Test Docker build process"
    @echo "     just test-basic             # Test basic functionality"
    @echo "     just test-scripts           # Validate script permissions"
    @echo ""
    @echo "  5. Maintenance:"
    @echo "     just update                 # Update Docker image"
    @echo "     just clean                  # Clean build artifacts"
    @echo "     just deep-clean             # Full cleanup including Docker"
    @echo ""
    @echo "Environment variables:"
    @echo "  PARALLEL_BUILDS={{PARALLEL_BUILDS}}     # Number of parallel build jobs"
    @echo "  BUILD_TIMEOUT={{BUILD_TIMEOUT}}      # Build timeout in seconds"
    @echo ""
    @echo "For more information:"
    @echo "  just --list                   # Show all available commands"
    @echo "  just status                   # Show project status"

# Show examples for different use cases
examples:
    @echo "Example Usage Scenarios"
    @echo "======================"
    @echo ""
    @echo "🎮 Building prefixes for gaming:"
    @echo "  just list-releases proton-ge 5  # Check latest Proton-GE releases"
    @echo "  just build-ge GE-Proton10-10"
    @echo "  just install"
    @echo "  just run-app ~/Games/MyGame/game.exe"
    @echo "  just archive-prefix              # Create backup archive"
    @echo ""
    @echo "🔧 Development and testing:"
    @echo "  just build-docker-image"
    @echo "  just test-basic"
    @echo "  just build-ge GE-Proton10-9"
    @echo ""
    @echo "🏭 CI testing:"
    @echo "  just ci-test"
    @echo "  just test-scripts"
    @echo ""
    @echo "🔄 Maintenance workflow:"
    @echo "  just update-all"
    @echo "  just prepare-release"
    @echo "  just deep-clean"
    @echo ""
    @echo "🔍 Custom installations:"
    @echo "  just build-ge GE-Proton10-8"
    @echo "  just install ./output ~/.wine-prefixes/proton-ge"
    @echo "  just run-app winecfg ~/.wine-prefixes/proton-ge"