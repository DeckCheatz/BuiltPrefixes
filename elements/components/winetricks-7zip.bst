kind: manual

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

sources:
- kind: remote
  url: "https://www.7-zip.org/a/7z2409.exe"
  ref: "e35e4374100b52e697e002859aefdd5533bcbf4118e5d2210fae6de318947c41"

config:
  install-commands:
  - install -Dm644 -t "%{install-root}" 7z2409.exe

