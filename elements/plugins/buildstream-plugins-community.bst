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
- kind: tar
  url: pypi:96/44/8eda8dfdbe79124c5e67371a74d74e877b901bccedd647a4e24ad76d6bcd/buildstream_plugins_community-2.4.0.tar.gz
  ref: 6101ba093ed9a3c27f9faeefbcf08742b4c1e248e08c401df938bbeacbea0744
