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
# Repository: https://gitlab.com/BuildStream/buildstream-plugins-community
#
kind: junction

sources:
- kind: git
  url: gitlab:BuildStream/buildstream-plugins-community.git
  track: "master"
  ref: 2.3.1-2-g13bdcf608d7f32ecdd5127f367b5f53fa23dc8c4
