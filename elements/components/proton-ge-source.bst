# Proton-GE Source
#
# Downloads and extracts the Proton-GE custom Wine build from GloriousEggroll.
# Proton-GE is a custom build of Valve's Proton with additional patches and
# features for better game compatibility.
#
# Features included:
#   - Wine with Proton patches
#   - DXVK (DirectX 9/10/11 to Vulkan)
#   - VKD3D-Proton (DirectX 12 to Vulkan)
#   - FSR (FidelityFX Super Resolution)
#   - Various game-specific fixes
#
# Version configuration is in: include/proton-ge-config.yml
# Update version with: just update-config GE-Proton9-XX
#
# Output: Proton files at / (typically mounted at /proton in build)
#
kind: import

# Include external configuration for version, hash, and URL
(@):
- include/proton-ge-config.yml

sources:
- kind: tar
  url: "%{proton_ge_url}"
  ref: "%{proton_ge_hash}"
  # Extract to remove the versioned directory wrapper (e.g., GE-Proton9-20/)
  base-dir: "*"

config:
  # Import everything from the source archive
  source: "."
  target: "/"
