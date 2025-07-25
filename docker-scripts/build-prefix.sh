#!/bin/bash

set -euo pipefail

# build-prefix.sh - Build Wine prefixes using Proton releases in Docker
# Usage: ./build-prefix.sh [PROTON_URL] [OUTPUT_DIR]

PROTON_URL="${1:-}"
OUTPUT_DIR="${2:-/output}"
TEMP_DIR="/tmp/proton-build"

# Default Proton URL if none provided
if [[ -z "$PROTON_URL" ]]; then
    echo "Usage: $0 <PROTON_URL> [OUTPUT_DIR]"
    echo ""
    echo "Examples:"
    echo "  $0 'https://github.com/GloriousEggroll/proton-ge-custom/archive/GE-Proton10-10.tar.gz'"
    echo "  $0 'https://github.com/ValveSoftware/Proton/archive/proton-9.0-4.tar.gz'"
    exit 1
fi

echo "========================================="
echo "Docker Wine Prefix Builder"
echo "========================================="
echo "Proton URL: $PROTON_URL"
echo "Output Directory: $OUTPUT_DIR"
echo "Temp Directory: $TEMP_DIR"
echo ""

# Function to extract version from URL
extract_version() {
    local url="$1"
    
    # Extract GE-Proton version from releases URL
    if [[ "$url" =~ /releases/download/(GE-Proton[0-9]+-[0-9]+)/(GE-Proton[0-9]+-[0-9]+)\.tar\.gz ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    
    # Extract GE-Proton version from archive URL (legacy)
    if [[ "$url" =~ /archive/(GE-Proton[0-9]+-[0-9]+)\.tar\.gz ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    
    # Extract Valve Proton version from archive URL (legacy)
    if [[ "$url" =~ /archive/(proton-[0-9]+\.[0-9]+-*[0-9]*)\.tar\.gz ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    
    # Fallback
    echo "unknown-$(date +%Y%m%d-%H%M%S)"
}

# Function to determine vendor
determine_vendor() {
    local version="$1"
    
    if [[ "$version" =~ ^GE-Proton ]]; then
        echo "proton-ge"
    elif [[ "$version" =~ ^proton- ]] || [[ "$version" =~ ^[0-9]+\.[0-9]+ ]]; then
        echo "valve-proton"
    else
        echo "unknown"
    fi
}

# Extract version and vendor information
PROTON_VERSION=$(extract_version "$PROTON_URL")
PROTON_VENDOR=$(determine_vendor "$PROTON_VERSION")

echo "Detected version: $PROTON_VERSION"
echo "Detected vendor: $PROTON_VENDOR"
echo ""

# Create temp directories
mkdir -p "$TEMP_DIR" "$OUTPUT_DIR"

# Download and extract Proton binary release
echo "Downloading Proton binary release from: $PROTON_URL"
cd "$TEMP_DIR"
wget -O proton-binary.tar.gz "$PROTON_URL"
echo "Extracting Proton binary release..."
tar -xzf proton-binary.tar.gz
echo "Extraction complete. Contents:"
ls -la "$TEMP_DIR"

# Find the Proton directory (binary releases have a top-level directory)
PROTON_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d -name "*Proton*" | head -1)
if [[ -z "$PROTON_DIR" ]]; then
    # Fallback: look for any directory with proton script
    PROTON_SCRIPT=$(find "$TEMP_DIR" -name "proton" -type f | head -1)
    if [[ -n "$PROTON_SCRIPT" ]]; then
        PROTON_DIR=$(dirname "$PROTON_SCRIPT")
    else
        echo "Error: Could not find Proton directory in extracted archive"
        echo "Contents of temp directory:"
        ls -la "$TEMP_DIR"
        exit 1
    fi
fi

echo "Proton directory: $PROTON_DIR"

# Create machine-id if it doesn't exist (fixes Proton initialization)
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
export WINEDLLOVERRIDES="mscoree,mshtml="

# Create fake Steam directory structure to satisfy Proton requirements
mkdir -p "$STEAM_COMPAT_CLIENT_INSTALL_PATH"

# Set up Proton launcher
PROTON_LAUNCHER="$PROTON_DIR/proton"
if [[ ! -f "$PROTON_LAUNCHER" ]]; then
    echo "Error: Proton launcher not found at $PROTON_LAUNCHER"
    exit 1
fi

echo "Using Proton launcher: $PROTON_LAUNCHER"
chmod +x "$PROTON_LAUNCHER"

# Set up cleanup
cleanup() {
    echo "Cleaning up..."
    kill $XVFB_PID 2>/dev/null || true
    # Use Proton to kill wineserver
    if [[ -f "$PROTON_LAUNCHER" ]]; then
        STEAM_COMPAT_DATA_PATH="$STEAM_COMPAT_DATA_PATH" STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_COMPAT_CLIENT_INSTALL_PATH" python3 "$PROTON_LAUNCHER" run wineserver -k 2>/dev/null || true
    fi
}
trap cleanup EXIT

echo "Initializing Steam compatibility data directory..."
rm -rf "$STEAM_COMPAT_DATA_PATH"
mkdir -p "$STEAM_COMPAT_DATA_PATH"

echo "Initializing Wine prefix with Proton using Steam compat data path..."
# Initialize using a dummy executable to create the prefix structure
echo "#!/bin/bash" > "$STEAM_COMPAT_DATA_PATH/dummy.exe"
chmod +x "$STEAM_COMPAT_DATA_PATH/dummy.exe"
STEAM_COMPAT_DATA_PATH="$STEAM_COMPAT_DATA_PATH" STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_COMPAT_CLIENT_INSTALL_PATH" python3 "$PROTON_LAUNCHER" run "$STEAM_COMPAT_DATA_PATH/dummy.exe" || true
rm -f "$STEAM_COMPAT_DATA_PATH/dummy.exe"

# Wait for Wine to initialize
echo "Waiting for Wine initialization..."
timeout=60
while [[ ! -f "$WINEPREFIX/system.reg" ]] && [[ $timeout -gt 0 ]]; do
    echo "Waiting... ($timeout seconds remaining)"
    sleep 2
    timeout=$((timeout - 2))
done

if [[ ! -f "$WINEPREFIX/system.reg" ]]; then
    echo "Error: Wine prefix initialization failed"
    exit 1
fi

echo "Wine prefix initialized successfully"

# Install gaming components with winetricks
echo "Installing gaming components (SDL, CJK fonts, VKD3D, DXVK, .NET Framework)..."
STEAM_COMPAT_DATA_PATH="$STEAM_COMPAT_DATA_PATH" STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_COMPAT_CLIENT_INSTALL_PATH" \
    python3 "$PROTON_LAUNCHER" run winetricks -b sdl cjkfonts vkd3d dxvk2030 dotnet48

echo "Gaming components installation completed"

# Create output structure
PREFIX_NAME="${PROTON_VENDOR}-${PROTON_VERSION}"
OUTPUT_PREFIX_DIR="$OUTPUT_DIR/$PREFIX_NAME"
mkdir -p "$OUTPUT_PREFIX_DIR"/scripts

# Copy Steam compatibility data structure
echo "Copying Steam compatibility data to output..."
cp -r "$STEAM_COMPAT_DATA_PATH" "$OUTPUT_PREFIX_DIR/steam-compat-data"

# Copy Proton launcher to output
echo "Copying Proton launcher..."
cp -r "$PROTON_DIR" "$OUTPUT_PREFIX_DIR/proton"

# Create launcher script
cat > "$OUTPUT_PREFIX_DIR/scripts/run-app.sh" << 'LAUNCHER_EOF'
#!/bin/bash
# Generic Proton Prefix Launcher using Steam Compatibility Data

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"
STEAM_COMPAT_DATA_DIR="$PACKAGE_DIR/steam-compat-data"
PROTON_DIR="$PACKAGE_DIR/proton"

export STEAM_COMPAT_DATA_PATH="$STEAM_COMPAT_DATA_DIR"
export DISPLAY="${DISPLAY:-:0}"

# Application to run
APP_PATH="$1"

if [[ -z "$APP_PATH" ]]; then
    echo "Usage: $0 /path/to/application.exe"
    echo ""
    echo "This is a generic Proton prefix that can run any Windows application."
    echo "Examples:"
    echo "  $0 ~/Downloads/setup.exe          # Run an installer"
    echo "  $0 \"/path/to/My Game/game.exe\"    # Run a game"
    echo "  $0 winecfg                        # Configure Wine"
    exit 1
fi

# Check if Proton launcher exists
if [[ ! -f "$PROTON_DIR/proton" ]]; then
    echo "Error: Proton launcher not found at $PROTON_DIR/proton"
    exit 1
fi

# Check if Steam compat data exists
if [[ ! -d "$STEAM_COMPAT_DATA_DIR" ]]; then
    echo "Error: Steam compatibility data not found at $STEAM_COMPAT_DATA_DIR"
    exit 1
fi

# Run the application using Proton with Steam compatibility environment
exec env STEAM_COMPAT_DATA_PATH="$STEAM_COMPAT_DATA_PATH" STEAM_COMPAT_CLIENT_INSTALL_PATH="/tmp/steam-fake" python3 "$PROTON_DIR/proton" run "$APP_PATH" "${@:2}"
LAUNCHER_EOF

chmod +x "$OUTPUT_PREFIX_DIR/scripts/run-app.sh"

# Create installation script
cat > "$OUTPUT_PREFIX_DIR/scripts/install-prefix.sh" << 'INSTALL_EOF'
#!/bin/bash
# Generic Prefix Installation Script for Steam Compatibility Data

INSTALL_DIR="${1:-$HOME/.wine-prefixes/__PREFIX_NAME__}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="$(dirname "$SCRIPT_DIR")"

echo "Installing generic Proton prefix to: $INSTALL_DIR"
echo "This prefix uses Steam compatibility data structure and can run any Windows application."

# Create directory
mkdir -p "$INSTALL_DIR"

# Copy Steam compatibility data
if [[ -d "$PACKAGE_DIR/steam-compat-data" ]]; then
    cp -r "$PACKAGE_DIR/steam-compat-data" "$INSTALL_DIR/
fi

# Copy Proton launcher
if [[ -d "$PACKAGE_DIR/proton" ]]; then
    cp -r "$PACKAGE_DIR/proton" "$INSTALL_DIR/
fi

# Copy and update scripts
cp "$PACKAGE_DIR/scripts/run-app.sh" "$INSTALL_DIR/"
cp "$PACKAGE_DIR/README.md" "$INSTALL_DIR/" 2>/dev/null || true

echo ""
echo "Installation complete!"
echo ""
echo "Usage examples:"
echo "  cd '$INSTALL_DIR'"
echo "  ./run-app.sh /path/to/your/application.exe"
echo "  ./run-app.sh winecfg  # Configure Wine settings"
echo ""
echo "Note: This prefix uses Steam compatibility data structure at steam-compat-data/pfx"
echo ""
INSTALL_EOF

# Replace placeholder in install script
sed -i "s/__PREFIX_NAME__/$PREFIX_NAME/g" "$OUTPUT_PREFIX_DIR/scripts/install-prefix.sh"
chmod +x "$OUTPUT_PREFIX_DIR/scripts/install-prefix.sh"

# Create README
cat > "$OUTPUT_PREFIX_DIR/README.md" << README_EOF
# Generic Proton Prefix - $PREFIX_NAME

This is a generic Proton prefix that can run any Windows application using $PROTON_VENDOR $PROTON_VERSION.

## Quick Installation

\`\`\`bash
./scripts/install-prefix.sh [target-directory]
\`\`\`

## Usage

This prefix is designed to be universal and can run:

- **Games**: Steam, Epic, GOG, Origin, etc.
- **Applications**: Productivity software, utilities, etc.
- **Installers**: Setup files for any Windows software

### Running Applications

\`\`\`bash
# Run any Windows executable
./scripts/run-app.sh /path/to/application.exe

# Run Wine configuration
./scripts/run-app.sh winecfg

# Install software
./scripts/run-app.sh /path/to/setup.exe
\`\`\`

## Configuration

- **Wine Architecture**: win64 (64-bit)
- **Proton Version**: $PROTON_VERSION
- **Vendor**: $PROTON_VENDOR
- **Included**: SDL, CJK fonts, VKD3D, DXVK 2030, .NET Framework 4.8
- **Windows Version**: Windows 10
- **Steam Compatibility**: Uses STEAM_COMPAT_DATA_PATH structure for proper Proton integration

## Build Information

- **Source URL**: $PROTON_URL
- **Build Date**: $(date -u '+%Y-%m-%dT%H:%M:%SZ')
- **Builder**: Docker Wine Prefix Builder

## Compatibility

This prefix is optimized for broad compatibility and should work with:
- Most modern Windows games (DirectX 9/10/11/12)
- Windows applications requiring .NET Framework
- Legacy software with older Windows APIs
- Vulkan and OpenGL applications

For specific game compatibility, check ProtonDB: https://www.protondb.com/
README_EOF

# Create archive
echo "Creating archive..."
cd "$OUTPUT_DIR"
tar -czf "${PREFIX_NAME}.tar.gz" "$PREFIX_NAME"
zip -r "${PREFIX_NAME}.zip" "$PREFIX_NAME"

# Create metadata
cat > "${PREFIX_NAME}.json" << METADATA_EOF
{
  "name": "$PREFIX_NAME",
  "version": "$PROTON_VERSION",
  "vendor": "$PROTON_VENDOR",
  "source_url": "$PROTON_URL",
  "build_date": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "architecture": "win64",
  "windows_version": "win10",
  "redistributables": ["sdl", "cjkfonts", "vkd3d", "dxvk2030", "dotnet48"],
  "builder": "Docker Wine Prefix Builder"
}
METADATA_EOF

echo ""
echo "========================================="
echo "BUILD COMPLETED SUCCESSFULLY"
echo "========================================="
echo "Prefix: $PREFIX_NAME"
echo "Output directory: $OUTPUT_PREFIX_DIR"
echo "Archives created:"
echo "  - ${PREFIX_NAME}.tar.gz"
echo "  - ${PREFIX_NAME}.zip"
echo "  - ${PREFIX_NAME}.json (metadata)"
echo ""
echo "To use this prefix:"
echo "  1. Extract the archive"
echo "  2. Run: ./scripts/install-prefix.sh"
echo "  3. Use: ./run-app.sh /path/to/app.exe"