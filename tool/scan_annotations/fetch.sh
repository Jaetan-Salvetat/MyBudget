#!/usr/bin/env bash
# Recupere le corpus annote du scan depuis les release assets GitHub.
#
#   ./tool/scan_annotations/fetch.sh
#
# Restaure ml/scan/data/annotations/ — la supervision du tagger de roles.
# L'archive se suffit a elle-meme : chaque enregistrement porte les lignes et
# leur geometrie, aucune image n'est necessaire pour entrainer.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/tool/scan_annotations/lock.env"

DATA_DIR="$ROOT/ml/scan/data"
ARCHIVE="$(mktemp -d)/$ANNOTATIONS_ASSET"
URL="https://github.com/$ANNOTATIONS_REPOSITORY/releases/download/$ANNOTATIONS_RELEASE/$ANNOTATIONS_ASSET"

checksum() {
  if command -v sha256sum > /dev/null; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

echo "Telechargement de $ANNOTATIONS_ASSET depuis la release $ANNOTATIONS_RELEASE..."
curl --fail --location --progress-bar --output "$ARCHIVE" "$URL"

ACTUAL="$(checksum "$ARCHIVE")"
if [ "$ACTUAL" != "$ANNOTATIONS_SHA256" ]; then
  rm -f "$ARCHIVE"
  echo "Empreinte inattendue pour $ANNOTATIONS_ASSET" >&2
  echo "  attendue : $ANNOTATIONS_SHA256" >&2
  echo "  obtenue  : $ACTUAL" >&2
  exit 1
fi

mkdir -p "$DATA_DIR"
tar -xzf "$ARCHIVE" -C "$DATA_DIR"
rm -f "$ARCHIVE"
echo "Corpus annote installe sous ml/scan/data/annotations/"
