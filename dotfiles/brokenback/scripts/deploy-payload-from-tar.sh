#!/usr/bin/env bash
set -euo pipefail

archive="${1:-/tmp/brokenback-milestone2-8-visual-polish.tar}"
stage="/tmp/brokenback-milestone2-8-visual-polish-root-$(date +%Y%m%d-%H%M%S)"

sudo mkdir -p "$stage"
sudo tar -xf "$archive" -C "$stage"
sudo bash "$stage/install-milestone2-desktop.sh" "$stage/payload"
