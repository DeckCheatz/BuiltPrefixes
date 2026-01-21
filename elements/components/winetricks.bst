kind: manual

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

sources:
- kind: git_repo
  url: github:winetricks/winetricks
  track: "refs/tags/*"
  ref: 20250102-0-ge20b2f6f80d175f96208f51800130db7459dd28c
- kind: patch
  path: patches/winetricks/0001-vkd3d-Hardcode-version.patch
- kind: patch
  path: patches/winetricks/0002-vkd3d-Don-t-set-ownership.patch
- kind: patch
  path: patches/winetricks/0001-dxvk-Fix-extraction-under-sandboxing.patch

config:
  install-commands:
  - install -Dm755 -t "%{install-root}%{bindir}" src/winetricks
