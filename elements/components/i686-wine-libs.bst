# i686 GCC runtime libraries (libgcc_s / libstdc++) for running Proton's
# 32-bit wine binaries under an x86_64 host.
#
# Filters the freedesktop-sdk i686 junction's gcc-libs artifact down to its
# `gcc-libs` split only. Depending on the junction element directly would also
# stage its runtime closure (full i686 glibc), which overlaps the x86_64 base
# system.
kind: filter

build-depends:
- freedesktop-sdk.bst:cross-compilers/freedesktop-sdk-i686.bst:components/gcc-libs.bst

config:
  include:
  - runtime
  include-orphans: False
