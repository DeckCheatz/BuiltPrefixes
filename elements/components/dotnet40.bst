kind: manual

depends:
- freedesktop-sdk.bst:public-stacks/runtime-minimal.bst

sources:
- kind: remote
  url: "https://web.archive.org/web/2000/https://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe"
  ref: "65e064258f2e418816b304f646ff9e87af101e4c9552ab064bb74d281c38659f"

config:
  install-commands:
  - install -Dm644 -t "%{install-root}" dotNetFx40_Full_x86_x64.exe
