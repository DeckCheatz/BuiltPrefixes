# Wine prefix build (the heart of the project).
#
# Reproduces the former elements/deploy/prefix.bst inside the Nix sandbox:
#   1. wineboot -i           (initialise the prefix; win64 fallback like the .bst)
#   2. winetricks -q sdl vkd3d dxvk2030 dotnet48
#   3. install trainer-monitor.exe into C:\windows
#
# `proton` may be any Proton distribution — Proton-GE, UMU-Proton, CachyOS
# Proton, or Valve Proton. Their on-disk layouts differ slightly, so the build
# auto-detects:
#   - the payload directory: `files/` (modern Proton) or `dist/` (older Proton)
#   - whether a 32-bit `wine` binary exists (win32); otherwise it uses `wine64`
#
# Proton's Wine runs inside `protonFhs`. Everything it needs (Proton, winetricks,
# the download cache, the .exe) is already in the store, so the derivation itself
# needs no network. Output ($out) is the finished prefix *directory*.
{ lib
, runCommand
, writeShellScript
, makeFontsConf
, dejavu_fonts
, liberation_ttf
, protonFhs
, proton # Proton-GE root (flake input)
, winetricks
, winetricksCache
, trainerExe
, winetricksVerbs ? [ "sdl" "vkd3d" "dxvk2030" "dotnet48" ]
}:

let
  # Wine needs a valid fontconfig config or its GDI/font init fails, which in
  # turn makes GUI helpers (e.g. regedit, used by winetricks) fail to load.
  fontsConf = makeFontsConf {
    fontDirectories = [ dejavu_fonts liberation_ttf ];
  };

  buildScript = writeShellScript "build-wine-prefix" ''
    set -euo pipefail

    : "''${WORK:?WORK must be set}"

    export HOME="$WORK/home"
    export WINEPREFIX="$WORK/pfx"
    export XDG_CACHE_HOME="$HOME/.cache"
    mkdir -p "$HOME"

    # winetricks writes into its cache, so give it a writable copy.
    mkdir -p "$XDG_CACHE_HOME"
    cp -r --no-preserve=mode,ownership "${winetricksCache}" "$XDG_CACHE_HOME/winetricks"
    export W_CACHE="$XDG_CACHE_HOME/winetricks"
    export WINETRICKS_LATEST_VERSION_CHECK=disabled
    export W_OPT_UNATTENDED=1

    # Suppress Wine's Mono/Gecko network prompts (we're offline).
    export WINEDLLOVERRIDES="mscoree,mshtml="
    export WINEDEBUG="-all"
    export FONTCONFIG_FILE="${fontsConf}"

    # Locate the Proton payload dir: modern Proton uses files/, older uses dist/.
    if [ -d "${proton}/files/bin" ]; then
      PDIST="${proton}/files"
    elif [ -d "${proton}/dist/bin" ]; then
      PDIST="${proton}/dist"
    else
      echo "error: no Proton payload dir (files/bin or dist/bin) under ${proton}" >&2
      exit 1
    fi
    export PATH="$PDIST/bin:$PATH"

    # Headless display for the Windows installers.
    Xvfb :99 -screen 0 1024x768x24 -nolisten tcp >/dev/null 2>&1 &
    XVFB_PID=$!
    export DISPLAY=":99"
    # Give Xvfb a moment to come up.
    for _ in $(seq 1 30); do
      [ -e /tmp/.X11-unix/X99 ] && break
      sleep 0.2
    done

    cleanup() { kill "$XVFB_PID" 2>/dev/null || true; }
    trap cleanup EXIT

    # Step 1: initialise the prefix. Prefer a 32-bit (win32) prefix when the
    # distribution ships a 32-bit `wine`, falling back to win64 exactly as
    # elements/deploy/prefix.bst did. Distributions without a 32-bit `wine`
    # (e.g. new-WoW64 Valve builds) go straight to win64.
    if [ -x "$PDIST/bin/wine" ]; then
      export WINEARCH="win32"
      export WINE="$PDIST/bin/wine"
      if ! "$WINE" wineboot -i; then
        echo "win32 wineboot failed; retrying with win64..."
        export WINE="$PDIST/bin/wine64"
        export WINEARCH="win64"
        rm -rf "$WINEPREFIX"
        "$WINE" wineboot -i
      fi
    else
      echo "no 32-bit wine in this Proton; using win64..."
      export WINEARCH="win64"
      export WINE="$PDIST/bin/wine64"
      "$WINE" wineboot -i
    fi
    "$WINE" wineserver -w || true

    # Step 2: install Windows components from the offline cache.
    "${winetricks}/bin/winetricks" -q ${lib.escapeShellArgs winetricksVerbs}
    "$WINE" wineserver -w || true

    # Step 3: install trainer-monitor into C:\windows.
    install -Dm644 "${trainerExe}" "$WINEPREFIX/drive_c/windows/trainer-monitor.exe"

    "$WINE" wineserver -k || true
  '';
in
runCommand "wine-prefix"
{
  nativeBuildInputs = [ protonFhs ];
  passthru = { inherit proton; };
} ''
  export WORK="$PWD/work"
  mkdir -p "$WORK"

  # Run the build inside the FHS environment.
  proton-fhs ${buildScript}

  # Copy the finished prefix out of the (shared) work dir into $out.
  mkdir -p "$out"
  cp -a "$WORK/pfx/." "$out/"
''
