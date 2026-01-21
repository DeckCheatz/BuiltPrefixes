# Create Wine prefix with all necessary components
kind: manual

# Dependencies
build-depends:
- filename: components/proton-ge-source.bst
  config:
    location: '/proton'
- filename: components/dotnet48.bst
  config:
    location: "/wine-assets/dotnet48"
- filename: components/dotnet40.bst
  config:
    location: "/wine-assets/dotnet40"
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

    mkdir -pv /tmp/.cache/winetricks/dotnet4{8,0}
    cp -v /wine-assets/dotnet48/ndp48-x86-x64-allos-enu.exe /tmp/.cache/winetricks/dotnet48
    cp -v /wine-assets/dotnet40/dotNetFx40_Full_x86_x64.exe /tmp/.cache/winetricks/dotnet40
    
    # Install dotnet48 (this may take a while)
    winetricks -q dotnet48
