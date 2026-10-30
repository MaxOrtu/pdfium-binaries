#!/bin/bash -eux
# Companion fork: link gdi32/user32 as delay-loaded, as Chromium does, so
# pdfium.dll loads inside a sandbox with Win32k system calls disabled
# (MXC process container, Chromium renderer). PDFium checks
# IsUser32AndGdi32Available() before any GDI call and falls back to reading
# fonts from %WINDIR%\Fonts, so the delay-loaded DLLs are never touched there.

BUILD_GN="${1:?path to pdfium BUILD.gn}"

awk '
  { print }
  /"user32\.lib",/ { in_libs = 1; next }
  in_libs && /^ *\]/ {
    print "    ldflags = [ \"/DELAYLOAD:gdi32.dll\", \"/DELAYLOAD:user32.dll\" ]"
    print "    libs += [ \"delayimp.lib\" ]"
    in_libs = 0
  }
' "$BUILD_GN" > "$BUILD_GN.new"
mv "$BUILD_GN.new" "$BUILD_GN"

# exactly one insertion, or the build must not continue
[ "$(grep -c 'DELAYLOAD:gdi32.dll' "$BUILD_GN")" -eq 1 ]
