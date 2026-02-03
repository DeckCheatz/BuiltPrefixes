kind: manual

build-depends:
- freedesktop-sdk.bst:components/rust.bst
- freedesktop-sdk.bst:components/gcc.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

config:
  install-commands:
  - cargo install --no-track --locked --path . --root "%{install-root}%{prefix}"

sources:
- kind: git_repo
  url: github:DeckCheatz/trainer-monitor.git
  track: main
  ref: 716959bb049492034a864443c7b99503bb2f7335
