# i686 GnuTLS runtime libraries for Wine's 32-bit crypto support.
#
# Proton's WINEARCH=win32 prefix runs the pure 32-bit wine binary, which
# loads libgnutls.so via its own gnutls builtin (winegnutls) at runtime -
# distinct from the x86_64 components/gnutls.bst already staged for the
# host-side tools (curl, winetricks, etc). Without it, wine logs
# "failed to load libgnutls, no support for encryption" and secure
# connections (schannel, pfx import/export) are unavailable inside the
# prefix.
#
# Depending on the i686 junction's gnutls.bst (and its library dependencies)
# directly as build-depends would stage each one's full runtime-minimal
# closure (coreutils, bash, etc built for i686), overlapping the x86_64 base
# system - the exact problem components/i686-wine-libs.bst works around for
# gcc-libs. Filter every needed library down to its own runtime split
# (excluding headers/pkgconfig/static libs) instead of pulling their
# dependency closures.
kind: filter

build-depends:
- freedesktop-sdk.bst:cross-compilers/freedesktop-sdk-i686.bst:components/gnutls.bst

runtime-depends:
- freedesktop-sdk.bst:cross-compilers/freedesktop-sdk-i686.bst:components/nettle.bst
- freedesktop-sdk.bst:cross-compilers/freedesktop-sdk-i686.bst:components/gmp.bst
- freedesktop-sdk.bst:cross-compilers/freedesktop-sdk-i686.bst:components/libidn2.bst
- freedesktop-sdk.bst:cross-compilers/freedesktop-sdk-i686.bst:components/libtasn1.bst
- freedesktop-sdk.bst:cross-compilers/freedesktop-sdk-i686.bst:components/libunistring.bst
- freedesktop-sdk.bst:cross-compilers/freedesktop-sdk-i686.bst:components/p11-kit.bst
- freedesktop-sdk.bst:cross-compilers/freedesktop-sdk-i686.bst:components/libffi.bst

config:
  exclude:
  - devel
  - doc
  - license
  - locale
  include-orphans: True
