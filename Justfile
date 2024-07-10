# BuildStream Wine Prefix Builder - Minimal
# Requires: BuildStream 2.x, just
# All targets automatically calculate checksums for Proton-GE versions

# Default recipe - show available commands
default:
    @just --list

# Variables
bst_cmd := "bst"
default_element := "wine-prefix.bst"
output_dir := "./output"

# Check if BuildStream is installed
check-bst:
    #!/usr/bin/env bash
    if ! command -v {{bst_cmd}} &> /dev/null; then
        echo "BuildStream not found. Please install BuildStream 2.x"
        echo "pip install BuildStream2"
        exit 1
    fi

# Build wine prefix with default Proton-GE version
build: check-bst
    @echo "Building wine prefix with default Proton-GE version..."
    {{bst_cmd}} build {{default_element}}

# Build with specific Proton-GE version (calculates hash automatically)
build-version version: check-bst
    @echo "Building wine prefix with Proton-GE version: {{version}}"
    @echo "Updating Proton-GE configuration (calculating checksum)..."
    ./scripts/update-proton-config.py "{{version}}" --calculate-checksum
    {{bst_cmd}} build {{default_element}}

# Check out built artifacts
checkout element=default_element:
    @echo "Checking out built artifacts from {{element}}..."
    {{bst_cmd}} artifact checkout "{{element}}" --directory {{output_dir}}

# Show element configuration
show element=default_element: check-bst
    @echo "Showing element configuration for {{element}}..."
    {{bst_cmd}} show "{{element}}"

# Track source updates
track element=default_element: check-bst
    @echo "Tracking source updates for {{element}}..."
    {{bst_cmd}} source track --deps all "{{element}}"

# Update Proton-GE configuration (calculates checksum automatically)
update-config version:
    @echo "Updating Proton-GE configuration for {{version}} (calculating checksum)..."
    ./scripts/update-proton-config.py "{{version}}" --calculate-checksum

# Get checksum for any version without updating config
get-checksum version:
    @echo "Getting checksum for Proton-GE version {{version}}..."
    ./scripts/update-proton-config.py "{{version}}" --dry-run

# Clean build artifacts
clean: check-bst
    @echo "Cleaning build artifacts..."
    {{bst_cmd}} artifact delete --deps all "{{default_element}}"

# Clean output directories
clean-output:
    @echo "Cleaning output directories..."
    rm -rf {{output_dir}}

# Show project status
status:
    @echo "BuildStream Wine Prefix Builder Status:"
    @echo "======================================="
    @echo "Project: $(basename $(pwd))"
    @echo "BuildStream version: $({{bst_cmd}} --version 2>/dev/null || echo 'Not found')"
    @echo "Output directory: {{output_dir}}"
    @echo ""
    @echo "Available elements:"
    @ls elements/*.bst | sed 's/elements\//  - /' | sed 's/\.bst//'
