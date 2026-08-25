#!/usr/bin/env bash
# Publie le corpus d'images d'entrainement du classifieur de lignes dans les
# release assets GitHub.
#
#   ./tool/scan_corpus/publish.sh            # version suivante d'apres lock.env
#   ./tool/scan_corpus/publish.sh v2         # version imposee
#
# Ne publie que ce qui ne se reconstruit pas : les photos prises au telephone.
# FindIt, ExpressExpense et les corpus derives se retelechargent ou se
# regenerent via ml/scan/research/fetch_data.sh — les archiver ici doublerait
# des gigaoctets pour rien.
#
# Ces photos sont le seul terrain realiste du scan (papier froisse, perspective,
# ticket long photographie en paysage) et n'existent nulle part ailleurs :
# les perdre couterait une nouvelle campagne de prise de vue.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source tool/scan_corpus/lock.env

CORPUS_DIR="ml/scan/data/corpus"
SOURCES=("photos_pixel")

if [ $# -gt 1 ]; then
  echo "usage: ./tool/scan_corpus/publish.sh [version]" >&2
  exit 64
fi

if [ $# -eq 1 ]; then
  VERSION="$1"
else
  VERSION="v$(( ${CORPUS_RELEASE##*-v} + 1 ))"
fi

ASSET="scan-corpus-$VERSION.tar.gz"
RELEASE="scan-corpus-$VERSION"
ARCHIVE="$(mktemp -d)/$ASSET"

command -v gh > /dev/null || { echo "gh est requis" >&2; exit 69; }

if gh release view "$RELEASE" > /dev/null 2>&1; then
  echo "La release $RELEASE existe deja : choisir une version superieure." >&2
  exit 1
fi

for source in "${SOURCES[@]}"; do
  [ -d "$CORPUS_DIR/$source" ] || { echo "Corpus absent : $CORPUS_DIR/$source" >&2; exit 66; }
done

checksum() {
  if command -v sha256sum > /dev/null; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

echo "Archivage de ${SOURCES[*]}..."
tar -czf "$ARCHIVE" -C "$CORPUS_DIR" "${SOURCES[@]}"

SHA="$(checksum "$ARCHIVE")"
SIZE="$(du -h "$ARCHIVE" | cut -f1)"
IMAGES="$(find "${SOURCES[@]/#/$CORPUS_DIR/}" -type f \( -name '*.jpg' -o -name '*.png' \) | wc -l | tr -d ' ')"

echo "Publication de $RELEASE ($IMAGES images, $SIZE)..."
gh release create "$RELEASE" "$ARCHIVE" \
  --title "Corpus scan $VERSION" \
  --notes "Photos de tickets prises au telephone : le seul terrain realiste du
scan local, et le jeu d'evaluation du classifieur de lignes.

| | |
|---|---|
| archive | \`$ASSET\` |
| images | $IMAGES |
| taille | $SIZE |
| sha256 | \`$SHA\` |

Les corpus publics (FindIt, ExpressExpense) et les corpus derives ne sont pas
ici : \`ml/scan/research/fetch_data.sh\` les reconstruit.

Recupere par \`./tool/scan_corpus/fetch.sh\`, epingle dans
\`tool/scan_corpus/lock.env\`."

cat > tool/scan_corpus/lock.env <<EOF
# Corpus d'images du scan publie hors du depot : des centaines de mega-octets
# de photos, que LFS facturerait a chaque checkout de CI. Versionne ici, il
# rend chaque commit reproductible.
#
# Genere par tool/scan_corpus/publish.sh, a ne pas editer a la main.
CORPUS_REPOSITORY=$CORPUS_REPOSITORY
CORPUS_RELEASE=$RELEASE
CORPUS_ASSET=$ASSET
CORPUS_SHA256=$SHA
EOF

rm -f "$ARCHIVE"
echo
echo "Publie. Reste a committer : tool/scan_corpus/lock.env -> $RELEASE"
