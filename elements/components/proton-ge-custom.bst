kind: manual

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-make.bst

# Include external configuration
(@):
- include/proton-ge-config.yml

config:
  configure-commands:
  - ./patches/protonprep-valve-staging.sh
  - |
    mkdir build && cd build
    ../configure.sh --build-name=%{proton_ge_version}
  build-commands:
  - |
    mkdir build && cd build
    make redist

sources:
- kind: git_tag
  url: github:GloriousEggroll/proton-ge-custom
  use-lfs: True
  track: "%{proton_ge_version}"
  ref: GE-Proton9-20-0-gec2fa8a9b53a8b9eebc920611e4017ebde763601
