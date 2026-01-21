kind: manual

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

sources:
- kind: remote
  url: "https://github.com/doitsujin/dxvk/releases/download/v2.3/dxvk-2.3.tar.gz"
  ref: "8059c06fc84a864122cc572426f780f35921eb4e3678dc337e9fd79ee5a427c0"

config:
  install-commands:
  - install -Dm644 -t "%{install-root}" dxvk-2.3.tar.gz

