# Runtime environment with Wine tools using freedesktop-sdk
kind: script

build-depends:
- wine-runtime.bst
- proton-ge-source.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

# Build configuration
config:
  # Installation commands - minimal setup without network dependencies
  commands:
  # Skip ca-trust operations that are failing
  - |
    echo "Setting up basic Wine environment..."
    echo "freedesktop-sdk provides the necessary libraries"
    
    # Ensure ca-trust directories exist but don't run update-ca-trust
    mkdir -p /etc/pki/ca-trust/extracted
    chmod -R u+w /etc/pki/ca-trust/extracted || true
