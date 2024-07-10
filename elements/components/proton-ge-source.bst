# Download Proton-GE source release
kind: import

# Include external configuration
(@):
- include/proton-ge-config.yml

# Source configuration for downloading Proton-GE
sources:
- kind: tar
  url: "%{proton_ge_url}"
  ref: "%{proton_ge_hash}"
  base-dir: "*"  # Extract to remove the versioned directory wrapper

# Configuration for the import element
config:
  # Import everything from the source
  source: "."
  target: "/"
