{
  outputs = inputs: let
    inherit (inputs) self nixpkgs;

    forEachSystem = let
      inherit (nixpkgs.lib) genAttrs;
      genPkgs = system: nixpkgs.legacyPackages.${system};
      supportedSystems = [
        "x86_64-linux"
      ];
    in
      f: genAttrs supportedSystems (system: f (genPkgs system));
  in {
    devShells = forEachSystem (
      pkgs: {
        default = pkgs.mkShell {
          LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib/";
          nativeBuildInputs = with pkgs; [
            lzip
            buildbox
            python3Packages.packaging
            python3Packages.pip
          ];
        };
      }
    );
  };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";
  };
}
