# Create Wine prefix with all necessary components
kind: manual

# Dependencies
build-depends:
- filename: components/proton-ge-source.bst
  config:
    location: "/proton"
- filename: components/winetricks-packages.bst
  config:
    location: "/tmp/.cache/winetricks"
- components/winetricks.bst  
- freedesktop-sdk.bst:components/sed.bst
- freedesktop-sdk.bst:components/gawk.bst
- freedesktop-sdk.bst:components/grep.bst
- freedesktop-sdk.bst:components/freetype.bst

# Build configuration
config:
  build-commands:
    # Set up Wine environment from Proton-GE
  - |
    echo "Setting up Wine environment from Proton-GE..."
    mkdir -pv "%{prefix-root}"
    export PATH="/usr/bin:/bin:/proton:/proton/files/bin"

    # Initialize Wine prefix with Proton
  - |
    set -x
    echo "Initializing Wine prefix with wineboot..."
    $WINE wineboot
   
    # Install dotnet48 via winetricks
  - |
    set -x
    echo "Installing dependencies via winetricks..."
    winetricks sdl vkd3d dxvk2030 dotnet48
