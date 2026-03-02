kind: cargo

build-depends:
- freedesktop-sdk.bst:components/rust.bst
- freedesktop-sdk.bst:components/gcc.bst

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

sources:
- kind: git_repo
  url: github:DeckCheatz/trainer-monitor.git
  track: main
  ref: 716959bb049492034a864443c7b99503bb2f7335
