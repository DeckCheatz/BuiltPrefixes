# trainer-monitor — Rust watchdog cross-compiled to Windows 32-bit.
#
# Replaces the former elements/components/trainer-monitor.bst (a BuildStream
# `cargo` element). Target: i686-pc-windows-gnu, so the .exe runs in the 32-bit
# (win32/WoW64) Wine prefix.
#
# We build under the *cross* package set (`pkgsCross.mingw32`) so buildRustPackage
# targets i686-pc-windows-gnu and links with the i686-w64-mingw32 GCC toolchain,
# but we swap in fenix's *prebuilt* rustc + windows std: building rustc/std from
# source for this target is very slow and currently broken in nixpkgs (the 32-bit
# mingw std fails to link with `undefined reference to _Unwind_Resume`).
#
# Output: $out/bin/trainer-monitor.exe (a PE32 executable).
{ lib
, pkgsCross
, fenix # inputs.fenix.packages.${system}
, src
}:

let
  target = "i686-pc-windows-gnu";

  toolchain = fenix.combine [
    fenix.stable.cargo
    fenix.stable.rustc
    fenix.targets.${target}.stable.rust-std
    # Rust's own mingw-w64 runtime (crt2.o, libgcc_eh, ...), matching how the
    # prebuilt std was compiled. Used via `-C link-self-contained=y` below so we
    # do NOT link nixpkgs' mingw libgcc, which uses the incompatible mcfgthreads
    # threading model (missing `_MCF_*` / unwind symbols otherwise).
    fenix.targets.${target}.stable.rust-mingw
  ];

  # Cross package set -> stdenv whose hostPlatform is i686-w64-mingw32, so
  # buildRustPackage cross-compiles to i686-pc-windows-gnu and uses the mingw
  # GCC cross toolchain as the linker *driver* (rust supplies the runtime).
  rustPlatform = pkgsCross.mingw32.makeRustPlatform {
    cargo = toolchain;
    rustc = toolchain;
  };
in
rustPlatform.buildRustPackage {
  pname = "trainer-monitor";
  version = "0.1.0-unstable-56dea9a";

  inherit src;

  cargoLock.lockFile = "${src}/Cargo.lock";

  # Link against Rust's bundled (classic) mingw runtime instead of nixpkgs' mcf
  # mingw libgcc — the two are ABI-incompatible for unwinding.
  env.RUSTFLAGS = "-C link-self-contained=y";

  # Windows target — cannot execute the produced binary on the Linux builder.
  doCheck = false;

  meta = {
    description = "Win32/Linux watchdog for modding tools (cross-compiled to i686-pc-windows-gnu)";
    homepage = "https://github.com/DeckCheatz/trainer-monitor";
  };
}
