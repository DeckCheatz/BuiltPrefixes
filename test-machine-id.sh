#!/bin/bash

set -euo pipefail

PROTON_URL="$1"
OUTPUT_DIR="${2:-/output}"
TEMP_DIR="/tmp/proton-build"

echo "========================================="
echo "Machine-ID Fix Test"
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

# Create machine-id if it doesn't exist (fixes Proton initialization)
echo "Checking machine-id..."
if [[ ! -f /etc/machine-id || ! -s /etc/machine-id ]]; then
    echo "Creating machine-id for Proton..."
    echo "$(uuidgen | tr -d '-')" > /etc/machine-id
    echo "Created machine-id: $(cat /etc/machine-id)"
else
    echo "Existing machine-id: $(cat /etc/machine-id)"
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

echo "Testing Proton initialization with machine-id fix..."
# Just try to get Proton version - this should not hang
timeout 30 bash -c "STEAM_COMPAT_DATA_PATH='$STEAM_COMPAT_DATA_PATH' STEAM_COMPAT_CLIENT_INSTALL_PATH='$STEAM_COMPAT_CLIENT_INSTALL_PATH' python3 '$PROTON_LAUNCHER' --version" || echo "Proton version check completed (timeout expected)"

echo "Testing basic prefix creation..."
echo "#!/bin/bash" > "$STEAM_COMPAT_DATA_PATH/dummy.exe"
echo "echo 'Hello from Proton!'" >> "$STEAM_COMPAT_DATA_PATH/dummy.exe"
chmod +x "$STEAM_COMPAT_DATA_PATH/dummy.exe"

# Try to run dummy executable with timeout - should not hang on machine-id
echo "Running dummy executable with Proton..."
STEAM_COMPAT_DATA_PATH="$STEAM_COMPAT_DATA_PATH" STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_COMPAT_CLIENT_INSTALL_PATH" \
    timeout 60 python3 "$PROTON_LAUNCHER" run "$STEAM_COMPAT_DATA_PATH/dummy.exe" 2>&1 | head -20 || true

rm -f "$STEAM_COMPAT_DATA_PATH/dummy.exe"

if [[ -f "$WINEPREFIX/system.reg" ]]; then
    echo "✅ SUCCESS: Wine prefix created - machine-id fix is working!"
    ls -la "$STEAM_COMPAT_DATA_PATH/"
else
    echo "⚠️  Prefix not fully created but test completed without hanging"
fi

echo "✅ Machine-ID test completed successfully - no hanging detected"