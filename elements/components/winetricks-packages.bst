kind: manual

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

config:
  install-commands:
  - install -Dm644 -t "%{install-root}/7zip" 7z2409.exe
  - install -Dm644 -t "%{install-root}/dotnet40" dotNetFx40_Full_x86_x64.exe
  - install -Dm644 -t "%{install-root}/dotnet48" ndp48-x86-x64-allos-enu.exe
  - install -Dm644 -t "%{install-root}/dxvk2030" dxvk-2.3.tar.gz
  - install -Dm644 -t "%{install-root}/sdl" SDL-1.2.15-win32.zip
  - install -Dm644 -t "%{install-root}/vkd3d" vkd3d-proton-%{vkd3d-proton-version}.tar.zst

variables:
  vkd3d-proton-version: "3.0b"

sources:
- kind: remote
  url: "https://www.7-zip.org/a/7z2409.exe"
  ref: "e35e4374100b52e697e002859aefdd5533bcbf4118e5d2210fae6de318947c41"
- kind: remote
  url: "https://web.archive.org/web/1991/https://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe"
  ref: "65e064258f2e418816b304f646ff9e87af101e4c9552ab064bb74d281c38659f"
- kind: remote
  url: "https://web.archive.org/web/2000/https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/abd170b4b0ec15ad0222a809b761a036/ndp48-x86-x64-allos-enu.exe"
  ref: "95889d6de3f2070c07790ad6cf2000d33d9a1bdfc6a381725ab82ab1c314fd53"
- kind: remote
  url: "https://github.com/doitsujin/dxvk/releases/download/v2.3/dxvk-2.3.tar.gz"
  ref: "8059c06fc84a864122cc572426f780f35921eb4e3678dc337e9fd79ee5a427c0"
- kind: remote
  url: "https://web.archive.org/web/2000/https://www.libsdl.org/release/SDL-1.2.15-win32.zip"
  ref: "a28bbe38714ef7817b1c1e8082a48f391f15e4043402444b783952fca939edc1"
- kind: remote
  url: "https://github.com/HansKristian-Work/vkd3d-proton/releases/download/v%{vkd3d-proton-version}/vkd3d-proton-%{vkd3d-proton-version}.tar.zst"
  ref: "a21f5e511063b7fe80123910f1b54f75541f2edfef7106c461293f08982e9ad2"

