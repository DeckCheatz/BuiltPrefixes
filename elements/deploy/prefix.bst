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

# Virtual framebuffer for headless Wine initialisation (DISPLAY=:99)
- components/xorg-server-xvfb.bst

# trainer-monitor - Win32/Linux watchdog for modding tools.
- filename: components/trainer-monitor.bst
  config:
    location: "/tmp/trainer-monitor"

# Utilities required by winetricks and prefix setup
- freedesktop-sdk.bst:components/curl.bst
- freedesktop-sdk.bst:components/freetype.bst
- freedesktop-sdk.bst:components/gawk.bst
- freedesktop-sdk.bst:components/gnutls.bst
- freedesktop-sdk.bst:components/grep.bst
- freedesktop-sdk.bst:components/gzip.bst
- freedesktop-sdk.bst:components/sed.bst
- freedesktop-sdk.bst:components/tar.bst

# Base runtime
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

(?):
  - target_arch == 'x86_64':
# i686 cross-compiler for 32-bit Wine components
      build-depends:
        (>):
        - freedesktop-sdk.bst:cross-compilers/standard-libs-i686.bst
        - freedesktop-sdk.bst:cross-compilers/gcc-i686.bst
      environment:
        LD_LIBRARY_PATH: "/lib/sdk/toolchain-i386/i686-unknown-linux-gnu/lib/i386-linux-gnu:/usr/lib/i386-linux-gnu:/proton/files/lib64:/proton/files/lib/proton/files/lib"
  - target_arch == 'i686':
# Native 32-bit compiler for 32-bit Wine components
      build-depends:
        (>):
        - freedesktop-sdk.bst:bootstrap/glibc.bst
        - freedesktop-sdk.bst:components/gcc.bst
      environment:
        LD_LIBRARY_PATH: "/proton/files/lib/proton/files/lib"

environment:
  # Library paths for 32-bit and 64-bit Wine libraries
  # Include Proton binaries in PATH
  PATH: "/usr/bin:/bin:/proton:/proton/files/bin"
  # Temporary directory for Wine operations
  TMPDIR: "/tmp"
  WINE64: "/proton/files/bin/wine64"
  WINE32: "/proton/files/bin/wine"
  WINESERVER: "/proton/files/bin/wineserver"

config:
  build-commands:
  # Step 1: Create the Wine prefix directory structure
  - |
    echo "Setting up Wine environment from Proton-GE..."
    mkdir -pv "%{prefix-root}"

  # Step 2: Start virtual framebuffer so wineboot can launch explorer
  - |
    Xvfb :99 -screen 0 1280x1024x24 -nolisten tcp &
    echo $! > /tmp/xvfb.pid
    # Wait until Xvfb is accepting connections
    for i in $(seq 1 20); do
      xdpyinfo -display :99 >/dev/null 2>&1 && break
      sleep 0.5
    done

  # Step 3: Initialize Wine prefix - try WOW64 first, fall back to 32-bit
  # WOW64 runs 32-bit Windows apps inside a 64-bit Wine process (no 32-bit Linux libs needed).
  # Wineboot may return non-zero due to headless display-driver warnings even when the prefix
  # is fully created, so we test for drive_c/windows rather than the exit code.
  - |
    set -x

    # Attempt WOW64 (wine64 + win64 prefix)
    WINE="$WINE64" WINEARCH=win64 WINEPREFIX="%{prefix-root}" "$WINE64" wineboot -i 2>&1 || true

    if [ -d "%{prefix-root}/drive_c/windows" ]; then
      echo "WOW64 mode initialised successfully"
      printf 'WINE=%s\nWINEARCH=win64\n' "$WINE64" > /tmp/wine-mode
    else
      echo "WOW64 prefix creation failed, falling back to 32-bit mode"
      # Kill wineserver so it releases locks on the prefix before cleanup
      WINEPREFIX="%{prefix-root}" "$WINESERVER" -k 2>/dev/null || true
      sleep 1
      chmod -Rf u+w "%{prefix-root}" 2>/dev/null || true
      rm -rf "%{prefix-root}"
      mkdir -pv "%{prefix-root}"
      WINE="$WINE32" WINEARCH=win32 WINEPREFIX="%{prefix-root}" "$WINE32" wineboot -i 2>&1 || true
      printf 'WINE=%s\nWINEARCH=win32\n' "$WINE32" > /tmp/wine-mode
    fi

  # Step 3b: Disable hardware-access Wine services that fail in the build sandbox
  - |
    . /tmp/wine-mode
    export WINE WINEARCH WINEPREFIX="%{prefix-root}"
    DISPLAY=:99 "$WINE" reg add "HKLM\\SYSTEM\\CurrentControlSet\\Services\\winebth" /v Start /t REG_DWORD /d 4 /f 2>&1 || true
    DISPLAY=:99 "$WINE" reg add "HKLM\\SYSTEM\\CurrentControlSet\\Services\\wineusb" /v Start /t REG_DWORD /d 4 /f 2>&1 || true
    WINEPREFIX="%{prefix-root}" /proton/files/bin/wineserver -w 2>/dev/null || true

  # Step 4: Install Windows components via winetricks using the mode chosen above
  # -q flag runs in quiet/unattended mode
  - |
    . /tmp/wine-mode
    export WINE WINEARCH
    echo "Installing dependencies via winetricks (WINE=$WINE WINEARCH=$WINEARCH)..."
    winetricks -q vkd3d dxvk2030 dotnet48

  # Step 5: Install trainer-monitor into C:\Windows\system32
  - |
    echo "Installing trainer-monitor..."
    install -Dm644 -t "%{prefix-root}/drive_c/windows" /tmp/trainer-monitor/usr/bin/trainer-monitor.exe

  # Step 6: Stop Xvfb
  - |
    kill "$(cat /tmp/xvfb.pid)" 2>/dev/null || true

  # No binary stripping for Wine prefix
  strip-commands: []
