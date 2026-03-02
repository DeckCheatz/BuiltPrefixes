kind: manual

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

sources:
- kind: git_repo
  url: github:winetricks/winetricks
  track: "refs/tags/*"
  ref: 20260125-0-gb76e1ee79ac57d7aceb384f74518fc423265810c
- kind: patch
  path: patches/winetricks/0001-vkd3d-Hardcode-version-in-script.patch
- kind: patch
  path: patches/winetricks/0002-vkd3d-Don-t-set-ownership-upon-extraction.patch
- kind: patch
  path: patches/winetricks/0003-dxvk-Don-t-set-ownership-upon-extraction.patch

config:
  install-commands:
  - install -Dm755 -t "%{install-root}%{bindir}" src/winetricks
