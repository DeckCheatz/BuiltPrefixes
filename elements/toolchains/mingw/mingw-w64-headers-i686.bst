# MinGW-w64 headers for i686 Windows target
kind: autotools

build-depends:
- freedesktop-sdk.bst:public-stacks/buildsystem-autotools.bst
- freedesktop-sdk.bst:components/stripper.bst
- toolchains/mingw/binutils-i686.bst

variables:
  mingw-target: i686-w64-mingw32
  mingw-prefix: "%{prefix}/mingw-w64/%{mingw-target}"

environment-nocache:
- MAXJOBS

environment:
  MAXJOBS: '%{max-jobs}'

config:
  configure-commands:
  - |
    cd mingw-w64-headers
    ./configure \
      --prefix="%{mingw-prefix}" \
      --host="%{mingw-target}" \
      --enable-sdk=all \
      --enable-idl \
      --enable-secure-api

  build-commands:
  - make -C mingw-w64-headers -j${MAXJOBS}

  install-commands:
  - make -C mingw-w64-headers DESTDIR="%{install-root}" install
  # Create symlink for GCC to find the headers
  - |
    ln -sfv "%{mingw-prefix}" "%{install-root}%{mingw-prefix}/mingw"

sources:
- kind: git_repo
  url: github:mingw-w64/mingw-w64.git
  track: master
  ref: v13.0.0-560-g3197fc7d6146d2c53082e302112748a157ca0074
