# Set up Proton-GE environment
kind: script

# Dependencies
depends:
- filename: base-runtime.bst
  type: build
- filename: proton-ge-source.bst
  type: build
  config:
    location: '/proton'

# Build dependencies - ensure shell and basic tools are available
build-depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

# Build configuration
config:
  commands:
  # Set up basic environment
  - echo "Setting up Proton-GE environment..."

  # Set up Proton-GE Wine environment
  - |
    # Find the Proton installation - check common BuildStream locations
    PROTON_DIR="/proton"
    PROTON_EXEC="${PROTON_DIR}/proton"
    export PATH="$PROTON_DIR:$PATH"
    
    # Copy Proton installation to output in build directory
    mkdir -p "%{install-root}/prefix/proton"
    cp -Rv "$PROTON_DIR"/* "%{install-root}/prefix/proton/" 
