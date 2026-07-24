# Patched winetricks
#
# Winetricks is a plain shell script. We build it from the pinned upstream
# commit (carried over from the former elements/components/winetricks.bst) and
# apply the same three patches that adapt it for a network-isolated,
# non-root-owned sandbox:
#   0001 - hardcode the vkd3d-proton version (no version lookup over the network)
#   0002 - don't chown vkd3d files on extraction
#   0003 - don't chown dxvk files on extraction
{ lib
, stdenvNoCC
, fetchFromGitHub
}:

stdenvNoCC.mkDerivation {
  pname = "winetricks";
  version = "20260125";

  src = fetchFromGitHub {
    owner = "Winetricks";
    repo = "winetricks";
    rev = "b76e1ee79ac57d7aceb384f74518fc423265810c";
    hash = "sha256-uIBVESebsH7rXnxWd/qlrZxcG7Y486PctHzcLz29HDk=";
  };

  patches = [
    ../patches/winetricks/0001-vkd3d-Hardcode-version-in-script.patch
    ../patches/winetricks/0002-vkd3d-Don-t-set-ownership-upon-extraction.patch
    ../patches/winetricks/0003-dxvk-Don-t-set-ownership-upon-extraction.patch
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 src/winetricks "$out/bin/winetricks"
    runHook postInstall
  '';

  meta = {
    description = "Patched winetricks for offline sandbox prefix builds";
    homepage = "https://github.com/Winetricks/winetricks";
    license = lib.licenses.lgpl21Only;
    mainProgram = "winetricks";
  };
}
