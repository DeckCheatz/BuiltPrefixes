# Create Wine prefix with all necessary components
kind: manual

# Dependencies
build-depends:
- filename: components/proton-ge-source.bst
  config:
    location: "/proton"
- filename: components/winetricks-dotnet48.bst
  config:
    location: "/tmp/.cache/winetricks/dotnet48"
- filename: components/winetricks-dotnet40.bst
  config:
    location: "/tmp/.cache/winetricks/dotnet40"
- filename: components/winetricks-sdl.bst
  config:
    location: "/tmp/.cache/winetricks/sdl"
- filename: components/winetricks-7zip.bst
  config:
    location: "/tmp/.cache/winetricks/7zip"
- filename: components/winetricks-vkd3d.bst
  config:
    location: "/tmp/.cache/winetricks/vkd3d"
- filename: components/winetricks-dxvk.bst
  config:
    location: "/tmp/.cache/winetricks/dxvk2030"
- components/winetricks.bst  
- components/xorg-server-xvfb.bst
- freedesktop-sdk.bst:components/sed.bst
- freedesktop-sdk.bst:components/gawk.bst
- freedesktop-sdk.bst:cross-compilers/standard-libs-i686.bst
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

# Build configuration
config:
  build-commands:
    # Set up Wine environment from Proton-GE
  - |
    echo "Setting up Wine environment from Proton-GE..."
    mkdir -p "%{prefix-root}"

    # Initialize Wine prefix with Proton
  - |
    set -x
    echo "Initializing Wine prefix with wineboot..."
    
    # Start Xvfb for headless Wine initialization
    Xvfb "$DISPLAY" -screen 0 1024x768x24 &
    XVFB_PID=$!
    sleep 2

    export PATH="$PATH:/proton:/proton/files/bin"
    wine wineboot
   
    # Kill Xvfb
    kill $XVFB_PID || true
    
    # Install dotnet48 via winetricks
  - |
    set -x
    echo "Installing .NET Framework 4.8 via winetricks..."
    export PATH="$PATH:/proton:/proton/files/bin"

    winetricks -q sdl vkd3d dxvk2030 dotnet48
