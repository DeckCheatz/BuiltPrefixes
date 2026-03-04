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
- freedesktop-sdk.bst:components/curl.bst
- freedesktop-sdk.bst:components/freetype.bst
- freedesktop-sdk.bst:components/gawk.bst
- freedesktop-sdk.bst:components/grep.bst
- freedesktop-sdk.bst:components/gzip.bst
- freedesktop-sdk.bst:components/sed.bst
- freedesktop-sdk.bst:components/tar.bst
- freedesktop-sdk.bst:cross-compilers/gcc-i686.bst
- freedesktop-sdk.bst:cross-compilers/standard-libs-i686.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

environment:
  LD_LIBRARY_PATH: "/lib/sdk/toolchain-i386/i686-unknown-linux-gnu/lib/i386-linux-gnu:/usr/lib/i386-linux-gnu:/proton/files/lib64:/proton/files/lib/proton/files/lib"
  PATH: "/usr/bin:/bin:/proton:/proton/files/bin"
  TMPDIR: "/tmp"

# Build configuration
config:
  build-commands:
    # Set up Wine environment from Proton-GE
  - |
    echo "Setting up Wine environment from Proton-GE..."
    mkdir -pv "%{prefix-root}"

    # Initialize Wine prefix with Proton
  - |
    set -x
    echo "Initializing Wine prefix with wineboot..."
    $WINE wineboot
   
    # Install dotnet48 via winetricks
  - |
    set -x
    echo "Installing dependencies via winetricks..."
    winetricks -q sdl vkd3d dxvk2030 dotnet48

  strip-commands: []
