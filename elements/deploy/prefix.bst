# Wine Prefix Deployment
#
# Creates a fully configured Wine prefix with Proton-GE runtime and all
# necessary Windows components installed via winetricks.
#
# This is the main build target for the project. It:
#   1. Sets up the Wine environment from Proton-GE
#   2. Initializes the Wine prefix with wineboot
#   3. Installs Windows dependencies via winetricks:
#      - SDL (Simple DirectMedia Layer)
#      - VKD3D (DirectX 12 support)
#      - DXVK 2.3 (DirectX 9/10/11 support)
#      - .NET Framework 4.8
#
# Build command: bst build deploy/prefix.bst
# Extract artifacts: bst artifact checkout deploy/prefix.bst --directory=output
#
# Output: Wine prefix at %{prefix-root} (typically /pfx)
#
kind: manual

build-depends:
# Proton-GE runtime - mounted at /proton
- filename: components/proton-ge-source.bst
  config:
    location: "/proton"

# Pre-downloaded Windows packages - mounted at winetricks cache location
- filename: components/winetricks-packages.bst
  config:
    location: "/tmp/.cache/winetricks"

# Winetricks helper script
- components/winetricks.bst

# Utilities required by winetricks and prefix setup
- freedesktop-sdk.bst:components/curl.bst
- freedesktop-sdk.bst:components/freetype.bst
- freedesktop-sdk.bst:components/gawk.bst
- freedesktop-sdk.bst:components/grep.bst
- freedesktop-sdk.bst:components/gzip.bst
- freedesktop-sdk.bst:components/sed.bst
- freedesktop-sdk.bst:components/tar.bst

# i686 cross-compiler for 32-bit Wine components
- freedesktop-sdk.bst:cross-compilers/gcc-i686.bst
- freedesktop-sdk.bst:cross-compilers/standard-libs-i686.bst

# Base runtime
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

environment:
  # Library paths for 32-bit and 64-bit Wine libraries
  LD_LIBRARY_PATH: "/lib/sdk/toolchain-i386/i686-unknown-linux-gnu/lib/i386-linux-gnu:/usr/lib/i386-linux-gnu:/proton/files/lib64:/proton/files/lib/proton/files/lib"
  # Include Proton binaries in PATH
  PATH: "/usr/bin:/bin:/proton:/proton/files/bin"
  # Temporary directory for Wine operations
  TMPDIR: "/tmp"

config:
  build-commands:
  # Step 1: Create the Wine prefix directory structure
  - |
    echo "Setting up Wine environment from Proton-GE..."
    mkdir -pv "%{prefix-root}"

  # Step 2: Initialize Wine prefix with Proton's wineboot
  # This creates the basic Windows directory structure and registry
  - |
    set -x
    echo "Initializing Wine prefix with wineboot..."
    $WINE wineboot

  # Step 3: Install Windows components via winetricks
  # -q flag runs in quiet/unattended mode
  - |
    set -x
    echo "Installing dependencies via winetricks..."
    winetricks -q sdl vkd3d dxvk2030 dotnet48

  # No binary stripping for Wine prefix
  strip-commands: []
