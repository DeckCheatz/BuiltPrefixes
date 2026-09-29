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
  url: pypi:a8/3e/4827d60845eab67d93a3e0adf0ea86a86f80de75a07c8f410128c9cf9fe4/buildstream_plugins_community-2.3.3.tar.gz
  ref: 28ccf91c48044ea2889b2dc2a5b5644e5e625479d87a8feb7214a4d1bfd6179a
