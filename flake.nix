{
  description = "Nix build system for pre-configured Wine/Proton prefixes, output as a .tgz";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixpkgs-unstable";

    # The Proton runtime to build the prefix from. This is a plain tarball (not a
    # flake); Nix unpacks it and strips the single top-level directory, so the
    # input is the Proton root (files/ or dist/, proton, version, ...).
    #
    # The build is distribution-agnostic: it auto-detects the payload directory
    # (files/ vs dist/) and whether 32-bit Wine is present, so any Proton bundle
    # works. Select one at build time with `--override-input proton <tarball>`:
    #
    #   # Proton-GE (default)
    #   nix build .#prefix --override-input proton \
    #     https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton10-1/GE-Proton10-1.tar.gz
    #
    #   # UMU-Proton
    #   nix build .#prefix --override-input proton \
    #     https://github.com/Open-Wine-Components/umu-proton/releases/download/UMU-Proton-10.0-4/UMU-Proton-10.0-4.tar.gz
    #
    #   # CachyOS Proton
    #   nix build .#prefix --override-input proton \
    #     https://github.com/CachyOS/proton-cachyos/releases/download/cachyos-11.0-20260703-slr/proton-cachyos-11.0-20260703-slr-x86_64.tar.xz
    #
    #   # Valve Proton (no public tarball URL; point at an extracted Proton dir,
    #   # e.g. from a Steam install)
    #   nix build .#prefix --override-input proton \
    #     "path:$HOME/.steam/steam/steamapps/common/Proton 9.0 (Beta)"
    proton = {
      url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton9-12/GE-Proton9-12.tar.gz";
      flake = false;
    };

    # trainer-monitor application source (cross-compiled to Windows i686).
    trainer-monitor = {
      url = "github:DeckCheatz/trainer-monitor/56dea9a0838a300e9dcc9273df1f4a4ed3cfdf63";
      flake = false;
    };

    # Prebuilt Rust toolchains (incl. the i686-pc-windows-gnu std). Avoids
    # building rustc from source, whose 32-bit mingw std is currently broken.
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, ... }:
    let
      inherit (inputs) nixpkgs;

      supportedSystems = [ "x86_64-linux" ];

      forEachSystem = f:
        nixpkgs.lib.genAttrs supportedSystems
          (system: f (import nixpkgs { inherit system; }) system);

      # Derive a human-readable Proton version from the bundled `version` file
      # (falling back to "custom" for unusual archives). Used to name the tarball.
      protonVersion =
        let
          lib = nixpkgs.lib;
          versionFile = "${inputs.proton}/version";
          raw =
            if builtins.pathExists versionFile
            then builtins.readFile versionFile
            else "";
          tokens = builtins.filter (s: s != "")
            (lib.splitString " " (lib.replaceStrings [ "\n" "\t" ] [ " " " " ] raw));
        in
        if tokens == [ ] then "custom" else lib.last tokens;

      # This flake's own git revision, stamped into each prefix's metadata.json.
      # `self.rev` is only set for a clean tree; `dirtyRev` (suffixed "-dirty")
      # covers local/uncommitted builds.
      flakeRev = self.rev or self.dirtyRev or "unknown";
    in
    {
      packages = forEachSystem (pkgs: system:
        let
          winetricks = pkgs.callPackage ./nix/winetricks.nix { };
          winetricksCacheResult = pkgs.callPackage ./nix/winetricks-cache.nix { };
          protonFhs = pkgs.callPackage ./nix/proton-fhs.nix { };

          trainer-monitor = pkgs.callPackage ./nix/trainer-monitor.nix {
            src = inputs.trainer-monitor;
            fenix = inputs.fenix.packages.${system};
          };

          wine-prefix = pkgs.callPackage ./nix/wine-prefix.nix {
            inherit protonFhs winetricks protonVersion flakeRev;
            proton = inputs.proton;
            winetricksCache = winetricksCacheResult.cache;
            winetricksVersions = winetricksCacheResult.versions;
            trainerExe = "${trainer-monitor}/bin/trainer-monitor.exe";
          };

          # Package the prefix directory (including its metadata.json) into a
          # reproducible .tgz.
          prefix = pkgs.runCommand "wine-prefix-${protonVersion}.tar.gz"
            { nativeBuildInputs = [ pkgs.gzip pkgs.gnutar ]; }
            ''
              mkdir -p "$out"
              tar \
                --sort=name \
                --mtime='@0' \
                --owner=0 --group=0 --numeric-owner \
                -C ${wine-prefix} \
                -cf - . \
              | gzip -n -9 > "$out/wine-prefix-${protonVersion}.tar.gz"
            '';
        in
        {
          inherit winetricks protonFhs trainer-monitor wine-prefix prefix;
          winetricksCache = winetricksCacheResult.cache;
          default = prefix;
        });

      devShells = forEachSystem (pkgs: _system: {
        default = pkgs.mkShell {
          packages = [
            pkgs.nix
            pkgs.nixpkgs-fmt
            pkgs.just
            pkgs.python3
          ];
        };
      });

      formatter = forEachSystem (pkgs: _system: pkgs.nixpkgs-fmt);
    };
}
