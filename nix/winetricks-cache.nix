# Winetricks download cache
#
# Pre-fetches the Windows runtime packages that `winetricks -q sdl vkd3d
# dxvk2030 dotnet48` would otherwise download, and lays them out in the
# directory structure winetricks expects under $W_CACHE (one sub-directory per
# verb). Placing this at $XDG_CACHE_HOME/winetricks lets the prefix build run
# fully offline inside the Nix sandbox.
#
# URLs and sha256 checksums are carried over verbatim from the former
# elements/components/winetricks-packages.bst (BuildStream `remote` refs are
# plain sha256 hex, which fetchurl accepts directly).
#
# Returns `{ cache, versions }`: `cache` is the cache derivation consumed by
# `wine-prefix.nix`, `versions` is a plain `verb -> version` attrset used to
# stamp the built prefix's metadata.json with what was actually installed.
{ lib
, fetchurl
, runCommand
}:

let
  # verb -> { file, url, sha256, version }
  packages = {
    "7zip" = {
      file = "7z2409.exe";
      url = "https://www.7-zip.org/a/7z2409.exe";
      sha256 = "e35e4374100b52e697e002859aefdd5533bcbf4118e5d2210fae6de318947c41";
      version = "24.09";
    };
    "dotnet40" = {
      file = "dotNetFx40_Full_x86_x64.exe";
      url = "https://web.archive.org/web/1991/https://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe";
      sha256 = "65e064258f2e418816b304f646ff9e87af101e4c9552ab064bb74d281c38659f";
      version = "4.0";
    };
    "dotnet48" = {
      file = "ndp48-x86-x64-allos-enu.exe";
      url = "https://web.archive.org/web/2000/https://download.visualstudio.microsoft.com/download/pr/7afca223-55d2-470a-8edc-6a1739ae3252/abd170b4b0ec15ad0222a809b761a036/ndp48-x86-x64-allos-enu.exe";
      sha256 = "95889d6de3f2070c07790ad6cf2000d33d9a1bdfc6a381725ab82ab1c314fd53";
      version = "4.8";
    };
    "dxvk2030" = {
      file = "dxvk-2.3.tar.gz";
      url = "https://github.com/doitsujin/dxvk/releases/download/v2.3/dxvk-2.3.tar.gz";
      sha256 = "8059c06fc84a864122cc572426f780f35921eb4e3678dc337e9fd79ee5a427c0";
      version = "2.3";
    };
    "sdl" = {
      file = "SDL-1.2.15-win32.zip";
      url = "https://web.archive.org/web/2000/https://www.libsdl.org/release/SDL-1.2.15-win32.zip";
      sha256 = "a28bbe38714ef7817b1c1e8082a48f391f15e4043402444b783952fca939edc1";
      version = "1.2.15";
    };
    "vkd3d" = {
      file = "vkd3d-proton-3.0b.tar.zst";
      url = "https://github.com/HansKristian-Work/vkd3d-proton/releases/download/v3.0b/vkd3d-proton-3.0b.tar.zst";
      sha256 = "a21f5e511063b7fe80123910f1b54f75541f2edfef7106c461293f08982e9ad2";
      version = "3.0b";
    };
  };

  installOne = verb: p:
    let src = fetchurl { inherit (p) url sha256; };
    in "install -Dm644 ${src} \"$out/${verb}/${p.file}\"";

  installCommands = lib.concatStringsSep "\n" (lib.mapAttrsToList installOne packages);

  cache = runCommand "winetricks-cache" { } ''
    ${installCommands}
  '';
in
{
  inherit cache;
  versions = lib.mapAttrs (_verb: p: p.version) packages;
}
