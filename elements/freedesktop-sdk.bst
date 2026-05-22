# Freedesktop SDK Junction
#
# This junction provides access to the freedesktop-sdk, which contains:
#   - Base Linux runtime libraries (glibc, etc.)
#   - Build tools (GCC, autotools, cmake, etc.)
#   - Common libraries (GTK, Qt, etc.)
#   - Cross-compilers for i686 Linux
#
# Elements from this junction are referenced as:
#   freedesktop-sdk.bst:components/gcc.bst
#   freedesktop-sdk.bst:public-stacks/runtime-minimal.bst
#
# Documentation: https://gitlab.freedesktop.org/nicofabian/freedesktop-sdk
#
kind: junction

sources:
- kind: git_repo
  url: gitlab:freedesktop-sdk/freedesktop-sdk.git
  ref: freedesktop-sdk-25.08.12-0-gbb510d9021f4def1a60f032bef1e0ca660b8ec3a
  track: freedesktop-sdk-25.08.*

config:
  options:
    # Pass through target architecture to the junction
    target_arch: '%{target-arch}'
    # For i686 targets, use x86_64 for bootstrap to avoid circular dependencies
    (?):
    - target_arch == 'i686':
        bootstrap_build_arch: 'x86_64'
