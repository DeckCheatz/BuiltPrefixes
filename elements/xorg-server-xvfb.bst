# X.org server Xvfb - Virtual Framebuffer server (based on Manjaro PKGBUILD)
kind: meson

build-depends:
- freedesktop-sdk.bst:components/dbus.bst
- freedesktop-sdk.bst:components/libepoxy.bst
- freedesktop-sdk.bst:components/libtirpc.bst
- freedesktop-sdk.bst:components/libunwind.bst
- freedesktop-sdk.bst:components/mesa-headers.bst
- freedesktop-sdk.bst:components/pixman.bst
- freedesktop-sdk.bst:components/systemd.bst
- freedesktop-sdk.bst:components/xcb-util-image.bst
- freedesktop-sdk.bst:components/xcb-util-keysyms.bst
- freedesktop-sdk.bst:components/xcb-util-renderutil.bst
- freedesktop-sdk.bst:components/xcb-util-wm.bst
- freedesktop-sdk.bst:components/xcb-util.bst
- freedesktop-sdk.bst:components/xorg-font-util.bst
- freedesktop-sdk.bst:components/xorg-lib-x11.bst
- freedesktop-sdk.bst:components/xorg-lib-xdmcp.bst
- freedesktop-sdk.bst:components/xorg-lib-xfont2.bst
- freedesktop-sdk.bst:components/xorg-lib-xkbfile.bst
- freedesktop-sdk.bst:components/xorg-proto-xorgproto.bst
- freedesktop-sdk.bst:public-stacks/buildsystem-meson.bst

sources:
- kind: git
  url: https://gitlab.freedesktop.org/xorg/xserver.git
  ref: xorg-server-21.1.20
  track: xorg-server-21.1.*

config:
  # Disable hardened compiler flags to prevent module loading issues
  # (following Manjaro PKGBUILD approach)
  strip-commands:
  - |
    export CFLAGS="${CFLAGS/-fno-plt/}"
    export CXXFLAGS="${CXXFLAGS/-fno-plt/}"
    export LDFLAGS="${LDFLAGS/,-z,now/}"

  configure-commands:
  - |
    meson setup build \
      --prefix=%{prefix} \
      --libexecdir=%{prefix}/lib \
      --sbindir=%{prefix}/bin \
      --buildtype=plain \
      --wrap-mode=nofallback \
      -D b_lto=true \
      -D b_pie=true \
      -D ipv6=true \
      -D xvfb=true \
      -D xnest=false \
      -D xcsecurity=true \
      -D xorg=false \
      -D xephyr=false \
      -D glamor=true \
      -D udev=true \
      -D systemd_logind=true \
      -D suid_wrapper=false \
      -D xkb_dir=%{prefix}/share/X11/xkb \
      -D xkb_output_dir=%{prefix}/share/X11/xkb/compiled \
      -D dtrace=false \
      -D linux_acpi=false

  build-commands:
  - meson compile -C build

  install-commands:
  - meson install -C build --destdir=%{install-root}
  
  # Create symlink for compatibility
  - |
    mkdir -p %{install-root}%{prefix}/bin
    ln -sf Xvfb %{install-root}%{prefix}/bin/Xvfb

variables:
  # Disable hardened compiler flags
  CFLAGS: "-fno-plt"
  CXXFLAGS: "-fno-plt" 
  LDFLAGS: "-Wl,-z,now"
