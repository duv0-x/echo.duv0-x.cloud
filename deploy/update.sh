#!/bin/bash
# Installs the latest echo.duv0-x.cloud GitHub release on the Pi when it differs
# from the installed one. Run as root by gotosocial-update.timer.
set -euo pipefail

REPO=duv0-x/echo.duv0-x.cloud
DIR=/gotosocial
PREV="$DIR/.previous"

current=$(cat "$DIR/.release" 2>/dev/null || true)
tag=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["tag_name"])')
[ "$tag" = "$current" ] && exit 0

echo "updating ${current:-<none>} -> $tag"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
file="gotosocial_${tag#v}_linux_arm64.tar.gz"
curl -fsSL -o "$tmp/$file" "https://github.com/$REPO/releases/download/$tag/$file"
curl -fsSL -o "$tmp/checksums.txt" "https://github.com/$REPO/releases/download/$tag/checksums.txt"
(cd "$tmp" && sha256sum -c checksums.txt)
mkdir "$tmp/new"
tar -xzf "$tmp/$file" -C "$tmp/new"

wait_ready() {
  # First boot after a migration runs ANALYZE, which takes minutes on a Pi 3.
  for _ in $(seq 1 120); do
    curl -sf -o /dev/null http://127.0.0.1:8080/readyz && return 0
    sleep 5
  done
  return 1
}

systemctl stop gotosocial
# The DB is copied after a clean stop so it matches the binary being replaced.
rm -rf "$PREV"
mkdir -p "$PREV/storage"
cp -a "$DIR/gotosocial" "$DIR/web" "$PREV/"
cp -a "$DIR/storage/sqlite.db" "$PREV/storage/"

rm -rf "$DIR/web"
cp -a "$tmp/new/gotosocial" "$tmp/new/web" "$DIR/"
cp -a "$tmp/new/example/." "$DIR/example/"
chown -R gotosocial:gotosocial "$DIR"
systemctl start gotosocial

if wait_ready; then
  echo "$tag" > "$DIR/.release"
  echo "updated to $tag"
  exit 0
fi

echo "$tag did not become ready; rolling back" >&2
systemctl stop gotosocial
rm -rf "$DIR/web" "$DIR/storage/sqlite.db-wal" "$DIR/storage/sqlite.db-shm"
cp -a "$PREV/gotosocial" "$PREV/web" "$DIR/"
cp -a "$PREV/storage/sqlite.db" "$DIR/storage/"
chown -R gotosocial:gotosocial "$DIR"
systemctl start gotosocial
exit 1
