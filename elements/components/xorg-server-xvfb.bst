# X.org server Xvfb - Virtual Framebuffer server (based on Manjaro PKGBUILD)
kind: meson

depends:
- freedesktop-sdk.bst:components/dbus.bst
- freedesktop-sdk.bst:components/libepoxy.bst
- freedesktop-sdk.bst:components/libtirpc.bst
- freedesktop-sdk.bst:components/libunwind.bst
- freedesktop-sdk.bst:components/libxkbcommon.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:components/pixman.bst
- freedesktop-sdk.bst:components/systemd.bst
- freedesktop-sdk.bst:components/xcb-util-image.bst
- freedesktop-sdk.bst:components/xcb-util-keysyms.bst
- freedesktop-sdk.bst:components/xcb-util-renderutil.bst
- freedesktop-sdk.bst:components/xcb-util-wm.bst
- freedesktop-sdk.bst:components/xcb-util.bst
- freedesktop-sdk.bst:components/xorg-data-xkeyboard-config.bst
- freedesktop-sdk.bst:components/xorg-font-util.bst
- freedesktop-sdk.bst:components/xorg-lib-x11.bst
- freedesktop-sdk.bst:components/xorg-lib-xdmcp.bst
- freedesktop-sdk.bst:components/xorg-lib-xfont2.bst
- freedesktop-sdk.bst:components/xorg-lib-xkbfile.bst
- freedesktop-sdk.bst:components/xorg-proto-xorgproto.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst

sources:
- kind: git_repo
  url: https://gitlab.freedesktop.org/xorg/xserver.git
  track: xorg-server-*.*.*
  ref: xorg-server-21.1.21-0-g312a25c65c8a918fea2cc77abd0db07ec0fc421c

variables:
  meson-local: >-
    -Db_lto=true
    -Db_pie=true
    -Dipv6=false
    -Dxvfb=true
    -Dxnest=false
    -Dxcsecurity=false
    -Dxorg=false
    -Dxephyr=false
    -Dglamor=false
    -Dudev=true
    -Dsystemd_logind=false
    -Dsuid_wrapper=false
    -Ddtrace=false
    -Dlinux_acpi=false
  CFLAGS: "-fno-plt"
  CXXFLAGS: "-fno-plt"
  LDFLAGS: "-Wl,-z,now"
