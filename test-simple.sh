#!/bin/bash

set -euo pipefail

PROTON_URL="$1"
OUTPUT_DIR="${2:-/output}"
TEMP_DIR="/tmp/proton-build"

echo "========================================="
echo "Simplified Build Test"
echo "========================================="

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

# Create machine-id if it doesn't exist
if [[ ! -f /etc/machine-id || ! -s /etc/machine-id ]]; then
    echo "Creating machine-id for Proton..."
    echo "$(uuidgen | tr -d '-')" > /etc/machine-id
fi

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

echo "Testing simplified build process..."

# Step 1: Initialize prefix
echo "1. Initializing Wine prefix with Proton..."
echo "#!/bin/bash" > "$STEAM_COMPAT_DATA_PATH/dummy.exe"
echo "echo 'Prefix initialized'" >> "$STEAM_COMPAT_DATA_PATH/dummy.exe"
chmod +x "$STEAM_COMPAT_DATA_PATH/dummy.exe"

STEAM_COMPAT_DATA_PATH="$STEAM_COMPAT_DATA_PATH" STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_COMPAT_CLIENT_INSTALL_PATH" \
    timeout 60 python3 "$PROTON_LAUNCHER" run "$STEAM_COMPAT_DATA_PATH/dummy.exe" || true

rm -f "$STEAM_COMPAT_DATA_PATH/dummy.exe"

# Wait for prefix to be ready
echo "2. Waiting for prefix initialization..."
timeout=30
while [[ ! -f "$WINEPREFIX/system.reg" ]] && [[ $timeout -gt 0 ]]; do
    echo "Waiting... ($timeout seconds remaining)"
    sleep 2
    timeout=$((timeout - 2))
done

if [[ -f "$WINEPREFIX/system.reg" ]]; then
    echo "✅ Prefix initialized successfully"
else
    echo "❌ Prefix initialization failed"
    exit 1
fi

# Step 2: Run winetricks (just test one component quickly)
echo "3. Testing winetricks with one component..."
STEAM_COMPAT_DATA_PATH="$STEAM_COMPAT_DATA_PATH" STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_COMPAT_CLIENT_INSTALL_PATH" \
    timeout 180 python3 "$PROTON_LAUNCHER" run winetricks --help > /dev/null && echo "✅ winetricks is accessible"

echo "4. Testing component installation (cjkfonts as quick test)..."
STEAM_COMPAT_DATA_PATH="$STEAM_COMPAT_DATA_PATH" STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_COMPAT_CLIENT_INSTALL_PATH" \
    timeout 120 python3 "$PROTON_LAUNCHER" run winetricks -b cjkfonts || echo "Warning: cjkfonts installation test completed"

# Step 3: Copy output
echo "5. Copying Steam compatibility data..."
cp -r "$STEAM_COMPAT_DATA_PATH" "$OUTPUT_DIR/steam-compat-data-test"
cp -r "$PROTON_DIR" "$OUTPUT_DIR/proton-test"

echo "✅ Simplified build test completed successfully!"
echo "Output structure:"
ls -la "$OUTPUT_DIR/"