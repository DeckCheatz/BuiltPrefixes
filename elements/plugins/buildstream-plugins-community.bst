# BuildStream Plugins Community Junction
#
# This junction provides additional BuildStream plugins not included in the core:
#
# Element plugins:
#   - cargo: Build Rust projects with cargo
#
# Source plugins:
#   - cargo2: Enhanced cargo source with vendored dependency support
#   - git_repo: Git repository source with submodule support
#
# Usage in project.conf:
#   plugins:
#   - origin: junction
#     junction: plugins/buildstream-plugins-community.bst
#     elements:
#     - cargo
#     sources:
#     - cargo2
#     - git_repo
#
# Repository: https://gitlab.com/nicofabian/buildstream-plugins-community
#
kind: junction

sources:
- kind: git
  url: gitlab:nicofabian/buildstream-plugins-community.git
  track: master
  ref: f32f4c29dba1b68bc105f401b237628a159bb2ca
