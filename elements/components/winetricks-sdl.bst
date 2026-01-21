kind: manual

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

sources:
- kind: remote
  url: "https://web.archive.org/web/2000/https://www.libsdl.org/release/SDL-1.2.15-win32.zip"
  ref: "a28bbe38714ef7817b1c1e8082a48f391f15e4043402444b783952fca939edc1"

config:
  install-commands:
  - install -Dm644 -t "%{install-root}" SDL-1.2.15-win32.zip

