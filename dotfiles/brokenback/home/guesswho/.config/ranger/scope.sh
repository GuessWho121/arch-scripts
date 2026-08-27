#!/usr/bin/env sh
set -eu

path="$1"
width="${2:-80}"
height="${3:-24}"
mime="$(file --mime-type -Lb "$path" 2>/dev/null || printf 'application/octet-stream')"

case "$mime" in
  image/*)
    chafa --fill=block --symbols=block --size="${width}x${height}" "$path" 2>/dev/null || file "$path"
    exit 0
    ;;
  application/pdf)
    pdftotext -l 2 -nopgbrk "$path" - 2>/dev/null | sed -n '1,120p' || pdfinfo "$path" 2>/dev/null
    exit 0
    ;;
  video/*|audio/*)
    mediainfo "$path" 2>/dev/null | sed -n '1,120p' || file "$path"
    exit 0
    ;;
  text/*|application/json|application/xml|application/x-sh|application/x-shellscript)
    sed -n '1,160p' "$path"
    exit 0
    ;;
esac

case "$path" in
  *.zip|*.tar|*.tar.gz|*.tgz|*.tar.xz|*.7z|*.rar)
    bsdtar -tf "$path" 2>/dev/null | sed -n '1,120p' || file "$path"
    exit 0
    ;;
esac

file "$path"
