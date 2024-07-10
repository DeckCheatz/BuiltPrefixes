# Optimized base runtime using freedesktop-sdk runtime-minimal
kind: import

# Use freedesktop-sdk platform as base (freedesktop-sdk 25.08 structure)
build-depends:
- freedesktop-sdk.bst:platform.bst

# Import needs an empty source since we're importing from build-depends
sources:
- kind: local
  path: .

# Configuration for import
config:
  source: ""
  target: "/"
