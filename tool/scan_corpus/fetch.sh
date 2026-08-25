#!/usr/bin/env bash
# Recupere le corpus d'images du scan depuis les release assets GitHub.
#
#   ./tool/scan_corpus/fetch.sh
#
# Restaure les photos de tickets sous ml/scan/data/corpus/. Les corpus publics
# et derives ne sont pas ici : ml/scan/research/fetch_data.sh les reconstruit.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/tool/scan_corpus/lock.env"

CORPUS_DIR="$ROOT/ml/scan/data/corpus"
ARCHIVE="$(mktemp -d)/$CORPUS_ASSET"
URL="https://github.com/$CORPUS_REPOSITORY/releases/download/$CORPUS_RELEASE/$CORPUS_ASSET"

checksum() {
  if command -v sha256sum > /dev/null; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

echo "Telechargement de $CORPUS_ASSET depuis la release $CORPUS_RELEASE..."
curl --fail --location --progress-bar --output "$ARCHIVE" "$URL"

ACTUAL="$(checksum "$ARCHIVE")"
if [ "$ACTUAL" != "$CORPUS_SHA256" ]; then
  rm -f "$ARCHIVE"
  echo "Empreinte inattendue pour $CORPUS_ASSET" >&2
  echo "  attendue : $CORPUS_SHA256" >&2
  echo "  obtenue  : $ACTUAL" >&2
  exit 1
fi

mkdir -p "$CORPUS_DIR"
tar -xzf "$ARCHIVE" -C "$CORPUS_DIR"
rm -f "$ARCHIVE"
echo "Corpus installe sous ml/scan/data/corpus/"
