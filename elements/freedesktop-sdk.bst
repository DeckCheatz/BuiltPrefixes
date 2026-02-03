kind: junction

sources:
- kind: git_repo
  url: gitlab:freedesktop-sdk/freedesktop-sdk.git
  ref: freedesktop-sdk-25.08.7-0-g8287748d639f575825280f6d67eec48d60718efa
  track: freedesktop-sdk-25.08.*

config:
  options:
    target_arch: '%{target-arch}'
    bootstrap_build_arch: '%{target-arch}'
    (?):
    - target_arch == 'i686':
        bootstrap_build_arch: 'x86_64'

