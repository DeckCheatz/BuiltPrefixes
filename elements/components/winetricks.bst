# Winetricks
#
# Winetricks is a helper script for Wine that automates the installation of:
#   - Windows DLLs (vcrun, directx, etc.)
#   - Windows applications (.NET Framework, fonts, etc.)
#   - Registry tweaks and workarounds
#
# This element applies patches for:
#   - VKD3D version detection
#   - File ownership issues during extraction
#   - DXVK extraction fixes
#
# Installed to: %{bindir}/winetricks
#
# Usage in Wine prefix:
#   winetricks -q vcrun2019 dotnet48 dxvk
#
# Repository: https://github.com/Winetricks/winetricks
#
kind: manual

depends:
# Runtime dependencies for winetricks script execution
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

config:
  # Winetricks is a shell script, no stripping needed
  strip-commands: []

  install-commands:
  # Install the winetricks script to bin directory
  - install -Dm755 -t "%{install-root}%{bindir}" src/winetricks

sources:
# Main winetricks repository
- kind: git_repo
  url: github:winetricks/winetricks
  track: "refs/tags/*"
  ref: 20260125-0-gb76e1ee79ac57d7aceb384f74518fc423265810c

# Patches for compatibility fixes
- kind: patch
  path: patches/winetricks/0001-vkd3d-Hardcode-version-in-script.patch
- kind: patch
  path: patches/winetricks/0002-vkd3d-Don-t-set-ownership-upon-extraction.patch
- kind: patch
  path: patches/winetricks/0003-dxvk-Don-t-set-ownership-upon-extraction.patch
