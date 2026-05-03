# Winetricks Packages
#
# Pre-downloaded Windows runtime packages for offline winetricks installation.
# These files are cached to avoid network downloads during Wine prefix creation.
#
# Included packages:
#   - 7-Zip 24.09: Archive utility (used by winetricks for extraction)
#   - .NET Framework 4.0: Legacy .NET runtime
#   - .NET Framework 4.8: Current .NET Framework runtime
#   - DXVK 2.3: DirectX 9/10/11 to Vulkan translation layer
#   - SDL 1.2.15: Simple DirectMedia Layer for legacy games
#   - VKD3D-Proton 3.0b: DirectX 12 to Vulkan translation layer
#
# Files are installed to directories matching winetricks cache structure.
# Mount this at /tmp/.cache/winetricks in your build.
#
# Note: Some URLs use web.archive.org for stability as Microsoft
# frequently changes download locations.
#
kind: manual

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  # VKD3D-Proton version - update here to change version globally
  vkd3d-proton-version: "3.0b"

config:
  install-commands:
  # Install each package to its winetricks cache directory
  - install -Dm644 -t "%{install-root}/7zip" 7z2409.exe
  - install -Dm644 -t "%{install-root}/dotnet40" dotNetFx40_Full_x86_x64.exe
  - install -Dm644 -t "%{install-root}/dotnet48" ndp48-x86-x64-allos-enu.exe
  - install -Dm644 -t "%{install-root}/dxvk2030" dxvk-2.3.tar.gz
  - install -Dm644 -t "%{install-root}/sdl" SDL-1.2.15-win32.zip
  - install -Dm644 -t "%{install-root}/vkd3d" vkd3d-proton-%{vkd3d-proton-version}.tar.zst

  # Binary packages, no stripping
  strip-commands: []

sources:
# 7-Zip - archive utility
- kind: remote
  url: "git_https:www.7-zip.org/a/7z2409.exe"
  ref: "e35e4374100b52e697e002859aefdd5533bcbf4118e5d2210fae6de318947c41"

# .NET Framework 4.0 - via archive.org for stability
- kind: remote
  url: "git_https:web.archive.org/web/1991/https://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe"
  ref: "65e064258f2e418816b304f646ff9e87af101e4c9552ab064bb74d281c38659f"

# .NET Framework 4.8 - via archive.org for stability
- kind: remote
  url: "git_https:web.archive.org/web/2000/https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/abd170b4b0ec15ad0222a809b761a036/ndp48-x86-x64-allos-enu.exe"
  ref: "95889d6de3f2070c07790ad6cf2000d33d9a1bdfc6a381725ab82ab1c314fd53"

# DXVK 2.3 - DirectX 9/10/11 to Vulkan
- kind: remote
  url: "github:doitsujin/dxvk/releases/download/v2.3/dxvk-2.3.tar.gz"
  ref: "8059c06fc84a864122cc572426f780f35921eb4e3678dc337e9fd79ee5a427c0"

# SDL 1.2.15 - legacy SDL for older games
- kind: remote
  url: "git_https:web.archive.org/web/2000/https://www.libsdl.org/release/SDL-1.2.15-win32.zip"
  ref: "a28bbe38714ef7817b1c1e8082a48f391f15e4043402444b783952fca939edc1"

# VKD3D-Proton - DirectX 12 to Vulkan
- kind: remote
  url: "github:HansKristian-Work/vkd3d-proton/releases/download/v%{vkd3d-proton-version}/vkd3d-proton-%{vkd3d-proton-version}.tar.zst"
  ref: "a21f5e511063b7fe80123910f1b54f75541f2edfef7106c461293f08982e9ad2"
