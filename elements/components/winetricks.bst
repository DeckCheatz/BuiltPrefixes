kind: manual

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

sources:
- kind: git_repo
  url: github:winetricks/winetricks
  track: "refs/tags/*"
  ref: 20250102-0-ge20b2f6f80d175f96208f51800130db7459dd28c

config:
  install-commands:
  - install -Dm755 -t "%{install-root}%{bindir}" src/winetricks
