#!/bin/bash

set -euo pipefail

PROTON_URL="$1"
OUTPUT_DIR="${2:-/output}"
TEMP_DIR="/tmp/proton-build"

echo "========================================="
echo "Steam Proton Initialization Test"
echo "========================================="
echo "Proton URL: $PROTON_URL"
echo "Output Directory: $OUTPUT_DIR"
echo ""

# Create temp directories
mkdir -p "$TEMP_DIR" "$OUTPUT_DIR"

# Download and extract Proton binary release
echo "Downloading Proton binary release..."
cd "$TEMP_DIR"
wget -O proton-binary.tar.gz "$PROTON_URL"
tar -xzf proton-binary.tar.gz

# Find the Proton directory
PROTON_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "*Proton*" | head -1)
echo "Proton directory: $PROTON_DIR"

# Set up virtual display
echo "Setting up virtual display..."
Xvfb :99 -screen 0 1024x768x24 -ac +extension GLX +render -noreset &
XVFB_PID=$!
sleep 3

# Set up Steam Proton environment
echo "Setting up Steam Proton environment..."
export STEAM_COMPAT_DATA_PATH="/steam-compat-data"
export STEAM_COMPAT_CLIENT_INSTALL_PATH="/tmp/steam-fake"
export WINEPREFIX="$STEAM_COMPAT_DATA_PATH/pfx"
export DISPLAY=:99

# Create fake Steam directory
mkdir -p "$STEAM_COMPAT_CLIENT_INSTALL_PATH"

# Set up Proton launcher
PROTON_LAUNCHER="$PROTON_DIR/proton"
chmod +x "$PROTON_LAUNCHER"

# Set up cleanup
cleanup() {
    echo "Cleaning up..."
    kill $XVFB_PID 2>/dev/null || true
}
trap cleanup EXIT

echo "Initializing Steam compatibility data directory..."
rm -rf "$STEAM_COMPAT_DATA_PATH"
mkdir -p "$STEAM_COMPAT_DATA_PATH"

echo "Initializing Wine prefix with Proton using Steam compat data path..."
# Create a simple dummy executable to trigger prefix creation
echo "#!/bin/bash" > "$STEAM_COMPAT_DATA_PATH/dummy.exe"
echo "echo 'Hello from Proton!'" >> "$STEAM_COMPAT_DATA_PATH/dummy.exe"
chmod +x "$STEAM_COMPAT_DATA_PATH/dummy.exe"

# Run dummy executable to initialize prefix
STEAM_COMPAT_DATA_PATH="$STEAM_COMPAT_DATA_PATH" STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_COMPAT_CLIENT_INSTALL_PATH" \
    timeout 60 python3 "$PROTON_LAUNCHER" run "$STEAM_COMPAT_DATA_PATH/dummy.exe" || echo "Dummy run completed (timeout is normal)"

rm -f "$STEAM_COMPAT_DATA_PATH/dummy.exe"

# Wait for Wine to initialize
echo "Waiting for Wine initialization..."
timeout=30
while [[ ! -f "$WINEPREFIX/system.reg" ]] && [[ $timeout -gt 0 ]]; do
    echo "Waiting... ($timeout seconds remaining)"
    sleep 2
    timeout=$((timeout - 2))
done

if [[ -f "$WINEPREFIX/system.reg" ]]; then
    echo "✓ Wine prefix initialized successfully"
    echo "✓ Steam compatibility data structure created"
    echo ""
    echo "Contents of Steam compat data:"
    ls -la "$STEAM_COMPAT_DATA_PATH/"
    echo ""
    echo "Contents of Wine prefix:"
    ls -la "$WINEPREFIX/" | head -10
    echo ""
    
    # Copy to output for inspection
    cp -r "$STEAM_COMPAT_DATA_PATH" "$OUTPUT_DIR/steam-compat-data-test"
    cp -r "$PROTON_DIR" "$OUTPUT_DIR/proton-test"
    
    echo "✓ Test completed successfully - output copied to $OUTPUT_DIR"
else
    echo "❌ Wine prefix initialization failed"
    exit 1
fi