# Main pipeline element - Complete Wine prefix with Proton-GE
kind: compose

# Dependencies - all the components we need
build-depends:
- deploy/proton/proton-prefix-creator.bst

# Configuration for the compose element
config:
  integrate: true
  # Include all artifacts from dependencies
  include-orphans: false
