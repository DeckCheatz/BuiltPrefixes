kind: junction

sources:
- kind: git_repo
  url: gitlab:freedesktop-sdk/freedesktop-sdk.git
  ref: freedesktop-sdk-25.08.5-0-g95585daebf5a424bb5bcb260868c3245624a37e8
  track: freedesktop-sdk-25.08.*

config:
  options:
    target_arch: '%{target-arch}'
    bootstrap_build_arch: '%{target-arch}'
    (?):
    - target_arch == 'i686':
        bootstrap_build_arch: 'x86_64'

