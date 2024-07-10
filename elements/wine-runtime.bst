# Wine runtime using freedesktop-sdk 25.08 platform (includes all necessary components)
kind: import

# Use freedesktop-sdk platform which includes graphics, audio, and core libraries
build-depends:
- base.bst

# Import needs an empty source since we're importing from build-depends  
sources:
- kind: local
  path: .

# Configuration for import
config:
  source: ""
  target: "/"
