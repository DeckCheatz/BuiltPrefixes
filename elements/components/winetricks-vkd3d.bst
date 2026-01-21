kind: manual

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

variables:
  vkd3d-proton-version: "3.0b"

sources:
- kind: remote
  url: "https://github.com/HansKristian-Work/vkd3d-proton/releases/download/v%{vkd3d-proton-version}/vkd3d-proton-%{vkd3d-proton-version}.tar.zst"
  ref: "a21f5e511063b7fe80123910f1b54f75541f2edfef7106c461293f08982e9ad2"

config:
  install-commands:
  - install -Dm644 -t "%{install-root}" vkd3d-proton-%{vkd3d-proton-version}.tar.zst
