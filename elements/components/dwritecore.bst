# DWriteCore
#
# Microsoft's redistributable DirectWrite implementation (DWriteCore.dll),
# extracted from the Microsoft.WindowsAppSDK.DWrite NuGet package.
#
# Wine's builtin dwrite.dll raises EXCEPTION_ACCESS_VIOLATION when Chromium
# asks it to map characters for certain pages, crashing the renderer process
# of Chromium-based Windows apps (e.g. WeMod's in-app Map panel stays blank).
# Chromium loads a DWriteCore.dll next to its executable - or anywhere else
# on the standard DLL search path, such as system32 - in preference to the
# system dwrite.dll, so shipping the real thing in the built prefix avoids
# Wine's broken implementation entirely.
#
# Ported from the runtime download added in wemod-launcher commit 1822ec8
# ("Ship DWriteCore.dll to stop the renderer crashing under Wine") so the
# fix is baked into the prefix instead of fetched at launch time.
#
# Output: DWriteCore.dll at /
#
kind: manual

build-depends:
# Provides zipfile, used to pull the single DLL out of the nupkg below
- freedesktop-sdk.bst:components/python3.bst

sources:
# The nupkg is a plain zip archive; no NuGet-specific handling needed
- kind: remote
  url: "nuget:microsoft.windowsappsdk.dwrite/2.1.0/microsoft.windowsappsdk.dwrite.2.1.0.nupkg"
  ref: "91746abd6a780b84001f9c465507830d5a24c79912bc4aa0d35938c71c1c6b5f"

config:
  build-commands:
  - |
    python3 -c "
    import zipfile
    with zipfile.ZipFile('microsoft.windowsappsdk.dwrite.2.1.0.nupkg') as archive:
        with archive.open('runtimes-framework/win-x64/native/DWriteCore.dll') as src:
            with open('DWriteCore.dll', 'wb') as dst:
                dst.write(src.read())
    "

  install-commands:
  - install -Dm644 -t "%{install-root}" DWriteCore.dll

  strip-commands: []
