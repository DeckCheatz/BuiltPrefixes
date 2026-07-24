# FHS environment for running Proton's bundled Wine.
#
# Proton-GE ships its own Wine binaries built for the Steam Linux Runtime, so
# they expect a traditional /usr filesystem full of shared libraries rather than
# Nix's store layout. buildFHSEnv gives us exactly that: an FHS chroot (via
# bubblewrap) in which Proton's Wine, winetricks and the Windows installers can
# run. Nested bubblewrap works inside the Nix build sandbox.
#
# `runScript = "bash"` makes the wrapper a bash entrypoint, so the prefix build
# invokes it as `proton-fhs <script.sh>`.
{ buildFHSEnv }:

buildFHSEnv {
  name = "proton-fhs";
  runScript = "bash";

  # Proton ships 32-bit Wine (an i686 ELF whose interpreter is
  # /lib/ld-linux.so.2). Without multiArch, buildFHSEnv builds no 32-bit profile
  # at all, so that loader (and all 32-bit libs) are missing and win32 Wine
  # cannot start. This pulls in the 32-bit variants of everything in multiPkgs.
  multiArch = true;

  # Tools needed by prefix setup and winetricks (native, 64-bit is fine).
  targetPkgs = pkgs: (with pkgs; [
    bashInteractive
    coreutils
    findutils
    which
    gnused
    gnugrep
    gawk
    gnutar
    gzip
    xz
    zstd
    cabextract
    p7zip
    unzip
    wget
    curl
    perl
    procps
    util-linux
    # Headless X server for the Windows installers winetricks drives.
    xorg-server
    xauth
  ]);

  # Libraries Proton's Wine (and the DLLs it loads) links against. These are
  # provided in both 64- and 32-bit variants so 32-bit (win32) Wine works.
  multiPkgs = pkgs: (with pkgs; [
    glibc
    stdenv.cc.cc # libstdc++, libgcc_s
    zlib
    freetype
    fontconfig
    gnutls
    openssl
    libgcrypt
    libgpg-error
    libxml2
    ncurses
    gettext
    # Graphics / Vulkan
    libglvnd
    mesa
    vulkan-loader
    libdrm
    # ALSA / Pulse
    alsa-lib
    libpulseaudio
    # X client libraries
    libx11
    libxext
    libxrandr
    libxcursor
    libxi
    libxrender
    libxfixes
    libxcomposite
    libxxf86vm
    libxinerama
    libxcb
    libxau
    libxdmcp
  ]);
}
