#!/usr/bin/env bash
# Recupere les donnees du scan depuis les release assets GitHub.
#
#   ./tool/scan_data/fetch.sh                  # images + corpus annote
#   ./tool/scan_data/fetch.sh --annotations    # corpus annote seul (~11 Mo)
#
# `--annotations` suffit pour entrainer : chaque enregistrement porte les
# lignes, les mots et leur geometrie. Les images ne servent qu'a re-annoter et
# a inspecter un ticket a l'oeil.
#
# Les images arrivent DEJA TRIEES — selection francaise, nommage stable,
# verite externe sous open_prices/truth/. Rien a refaire apres un clone.
#
# Ne sont pas ici : `synthetic` et les selections FindIt derivees, que
# ml/scan/research/fetch_data.sh regenere.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/tool/scan_data/lock.env"

ANNOTATIONS_ONLY=false
case "${1-}" in
  --annotations) ANNOTATIONS_ONLY=true ;;
  "") ;;
  *) echo "usage: ./tool/scan_data/fetch.sh [--annotations]" >&2; exit 64 ;;
esac

DATA_DIR="$ROOT/ml/scan/data"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

checksum() {
  if command -v sha256sum > /dev/null; then
    sha256sum | cut -d' ' -f1
  else
    shasum -a 256 | cut -d' ' -f1
  fi
}

verify() {
  local actual="$1" expected="$2" what="$3"
  if [ "$actual" != "$expected" ]; then
    echo "Empreinte inattendue pour $what" >&2
    echo "  attendue : $expected" >&2
    echo "  obtenue  : $actual" >&2
    exit 1
  fi
}

download() {
  local release="$1" asset="$2"
  curl --fail --location --progress-bar --output "$WORK/$asset" \
    "https://github.com/$SCAN_DATA_REPOSITORY/releases/download/$release/$asset"
}

echo "Telechargement de $ANNOTATIONS_ASSET..."
download "$ANNOTATIONS_RELEASE" "$ANNOTATIONS_ASSET"
verify "$(checksum < "$WORK/$ANNOTATIONS_ASSET")" "$ANNOTATIONS_SHA256" "$ANNOTATIONS_ASSET"
mkdir -p "$DATA_DIR"
tar -xzf "$WORK/$ANNOTATIONS_ASSET" -C "$DATA_DIR"
echo "Corpus annote installe sous ml/scan/data/annotations/"

if [ "$ANNOTATIONS_ONLY" = true ]; then
  exit 0
fi

read -r -a parts <<< "$IMAGES_ASSETS"
for asset in "${parts[@]}"; do
  echo "Telechargement de $asset..."
  download "$IMAGES_RELEASE" "$asset"
done

# Les morceaux ne valent rien pris un a un : l'empreinte porte sur le flux
# reconstitue, donc une seule verification apres reassemblage.
echo "Reassemblage de ${#parts[@]} morceaux..."
verify "$(cat "${parts[@]/#/$WORK/}" | checksum)" "$IMAGES_SHA256" "les images"

mkdir -p "$DATA_DIR/corpus"
cat "${parts[@]/#/$WORK/}" | tar -xzf - -C "$DATA_DIR/corpus"
echo "Images installees sous ml/scan/data/corpus/"
