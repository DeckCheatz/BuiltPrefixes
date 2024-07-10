# Create Wine prefix with all necessary components
kind: manual

# Dependencies
build-depends:
- filename: proton-setup.bst
  config:
    location: '/proton'
- winetricks.bst  
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
- freedesktop-sdk.bst:bootstrap/coreutils.bst
- xorg-server-xvfb.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-python.bst

environment:
  PATH: "/prefix/proton/bin:$PATH"

# Build configuration
config:
  build-commands:
    # Set up Wine environment from Proton-GE
  - |
    echo "Setting up Wine environment from Proton-GE..."
    mkdir -p "%{prefix-root}"
    
    # Initialize Wine prefix with Proton
  - |
    echo "Initializing Wine prefix with wineboot..."
    
    # Start Xvfb for headless Wine initialization
    Xvfb "$DISPLAY" -screen 0 1024x768x24 &
    XVFB_PID=$!
    sleep 2

    proton run
   
    # Kill Xvfb
    kill $XVFB_PID || true
    
    # Install dotnet48 via winetricks
  - |
    echo "Installing .NET Framework 4.8 via winetricks..."
    
    # Start Xvfb for winetricks
    Xvfb "$DISPLAY" -screen 0 1024x768x24 &
    XVFB_PID=$!
    sleep 2
    
    # Install dotnet48 (this may take a while)
    winetricks -q dotnet48
    
    # Kill Xvfb
    kill $XVFB_PID || true
