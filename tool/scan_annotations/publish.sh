#!/usr/bin/env bash
# Publie le corpus annote du scan dans les release assets GitHub.
#
#   ./tool/scan_annotations/publish.sh            # version suivante d'apres lock.env
#   ./tool/scan_annotations/publish.sh v2         # version imposee
#
# Pourquoi hors du depot, alors que c'est une verite d'entrainement : elle est
# reecrite EN BLOC a chaque evolution du prompt ou du format, et git garde un
# blob neuf par fichier a chaque passe. Le golden FindIt, lui, reste versionne
# — cure a la main, stable, irremplacable.
#
# Second motif : le depot est public et l'historique git ne s'efface pas. Ces
# tickets sont des photos personnelles de contributeurs ; un asset de release
# se remplace ou se supprime.
#
# L'archive se suffit a elle-meme pour entrainer : chaque enregistrement porte
# les lignes, les mots et leur geometrie. Les images ne servent qu'a
# re-annoter, et vivent dans tool/scan_corpus/ ou se retelechargent.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source tool/scan_annotations/lock.env

ANNOTATIONS_DIR="ml/scan/data/annotations"

if [ $# -gt 1 ]; then
  echo "usage: ./tool/scan_annotations/publish.sh [version]" >&2
  exit 64
fi

if [ $# -eq 1 ]; then
  VERSION="$1"
else
  VERSION="v$(( ${ANNOTATIONS_RELEASE##*-v} + 1 ))"
fi

ASSET="scan-annotations-$VERSION.tar.gz"
RELEASE="scan-annotations-$VERSION"
ARCHIVE="$(mktemp -d)/$ASSET"

command -v gh > /dev/null || { echo "gh est requis" >&2; exit 69; }

if gh release view "$RELEASE" > /dev/null 2>&1; then
  echo "La release $RELEASE existe deja : choisir une version superieure." >&2
  exit 1
fi

[ -d "$ANNOTATIONS_DIR" ] || { echo "Corpus annote absent : $ANNOTATIONS_DIR" >&2; exit 66; }

checksum() {
  if command -v sha256sum > /dev/null; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

echo "Archivage du corpus annote..."
tar -czf "$ARCHIVE" -C "$(dirname "$ANNOTATIONS_DIR")" "$(basename "$ANNOTATIONS_DIR")"

SHA="$(checksum "$ARCHIVE")"
SIZE="$(du -h "$ARCHIVE" | cut -f1)"
TICKETS="$(find "$ANNOTATIONS_DIR" -name '*.json' | wc -l | tr -d ' ')"
CORPORA="$(find "$ANNOTATIONS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | paste -sd', ' -)"

echo "Publication de $RELEASE ($TICKETS tickets, $SIZE)..."
gh release create "$RELEASE" "$ARCHIVE" \
  --title "Corpus annote scan $VERSION" \
  --notes "Tickets annotes ligne a ligne : la supervision du tagger de roles.

| | |
|---|---|
| archive | \`$ASSET\` |
| tickets | $TICKETS |
| corpus | $CORPORA |
| taille | $SIZE |
| sha256 | \`$SHA\` |

Chaque enregistrement porte les lignes physiques, leurs mots et leur
geometrie : l'archive suffit a entrainer sans aucune image. Le filtre
d'acceptation n'est PAS stocke, il est rejoue au chargement.

Recupere par \`./tool/scan_annotations/fetch.sh\`, epingle dans
\`tool/scan_annotations/lock.env\`."

cat > tool/scan_annotations/lock.env <<EOF
# Corpus annote du scan publie hors du depot : reecrit en bloc a chaque
# evolution du prompt ou du format, il ferait grossir l'historique git d'un
# blob par fichier a chaque passe. Versionne ici, il rend chaque commit
# reproductible — un vieux commit recupere le corpus sur lequel il a ete
# mesure.
#
# Genere par tool/scan_annotations/publish.sh, a ne pas editer a la main.
ANNOTATIONS_REPOSITORY=$ANNOTATIONS_REPOSITORY
ANNOTATIONS_RELEASE=$RELEASE
ANNOTATIONS_ASSET=$ASSET
ANNOTATIONS_SHA256=$SHA
EOF

rm -f "$ARCHIVE"
echo
echo "Publie. Reste a committer : tool/scan_annotations/lock.env -> $RELEASE"
