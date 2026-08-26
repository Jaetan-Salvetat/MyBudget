#!/usr/bin/env bash
# Publie les modeles du scan : assets versionnes, release GitHub, lock mis a
# jour.
#
#   ./tool/line_classifier/publish.sh            # version suivante d'apres lock.env
#   ./tool/line_classifier/publish.sh v7         # version imposee
#
# Les deux modeles portent la MEME version et vivent dans la meme release :
# ils sont utilises ensemble, et une app qui melangerait un tagger d'une
# version avec un classifieur d'une autre deciderait autrement que la
# reference. La version suivante est donc le successeur du plus avance des
# deux, jamais du seul classifieur.
#
# Le classifieur de lignes etiquette les lignes a prix et guide le decodeur ;
# le tagger de roles designe l'enseigne, la ligne de date et les libelles
# d'articles.
#
# Sources par defaut : ml/scan/research/models/line_clf.json et line_roles.json,
# produits par `uv run python -m line_classifier.export` et `...export_roles`.
# Surchargeables par CLASSIFIER_SOURCE et TAGGER_SOURCE.
#
# Rien n'est a editer a la main ensuite : le nom de l'asset est lu dans le
# manifeste par LocalReceiptScanner, et tool/line_classifier/lock.env est
# reecrit ici.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source tool/line_classifier/lock.env

CLASSIFIER_SOURCE="${CLASSIFIER_SOURCE:-ml/scan/research/models/line_clf.json}"
TAGGER_SOURCE="${TAGGER_SOURCE:-ml/scan/research/models/line_roles.json}"

if [ $# -gt 1 ]; then
  echo "usage: ./tool/line_classifier/publish.sh [version]" >&2
  exit 64
fi

version_of() {
  local asset="$1" prefix="$2"
  local stripped="${asset#"$prefix"}"
  echo "${stripped%.json}"
}

if [ $# -eq 1 ]; then
  VERSION="$1"
else
  CLASSIFIER_VERSION="$(version_of "$CLASSIFIER_ASSET" 'line_clf_v')"
  TAGGER_VERSION="$(version_of "${TAGGER_ASSET:-line_roles_v0.json}" 'line_roles_v')"
  CURRENT="$CLASSIFIER_VERSION"
  [ "$TAGGER_VERSION" -gt "$CURRENT" ] && CURRENT="$TAGGER_VERSION"
  VERSION="v$((CURRENT + 1))"
fi

ASSET="line_clf_$VERSION.json"
DESTINATION="assets/models/$ASSET"
TAGGER_ASSET="line_roles_$VERSION.json"
TAGGER_DESTINATION="assets/models/$TAGGER_ASSET"
RELEASE="scan-models-$VERSION"

command -v gh > /dev/null || { echo "gh est requis" >&2; exit 69; }

# Republier sous un tag existant laisserait les installations deja a jour sur
# les anciens modeles : l'app choisit ses assets par leur nom de fichier.
if gh release view "$RELEASE" > /dev/null 2>&1; then
  echo "La release $RELEASE existe deja : choisir une version superieure." >&2
  exit 1
fi

checksum() {
  if command -v sha256sum > /dev/null; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

# Le manifeste ne doit contenir qu'un exemplaire de chaque : l'app refuse de
# choisir entre deux versions.
publish_artifact() {
  local source="$1" destination="$2" pattern="$3"
  if [ -f "$source" ]; then
    find assets/models -name "$pattern" -delete
    cp "$source" "$destination"
  elif [ ! -f "$destination" ]; then
    echo "Ni $source ni $destination : rien a publier." >&2
    exit 66
  else
    echo "Pas de sortie d'entrainement, publication de $destination tel quel."
  fi
}

publish_artifact "$CLASSIFIER_SOURCE" "$DESTINATION" 'line_clf_v*.json'
publish_artifact "$TAGGER_SOURCE" "$TAGGER_DESTINATION" 'line_roles_v*.json'

SHA="$(checksum "$DESTINATION")"
SIZE="$(du -h "$DESTINATION" | cut -f1)"
TAGGER_SHA="$(checksum "$TAGGER_DESTINATION")"
TAGGER_SIZE="$(du -h "$TAGGER_DESTINATION" | cut -f1)"

echo "Publication de $RELEASE..."
gh release create "$RELEASE" "$DESTINATION" "$TAGGER_DESTINATION" \
  --title "Modeles du scan $VERSION" \
  --notes "Modeles du scan local. Les montants sont recopies de l'OCR, jamais
generes.

- **classifieur de lignes** : etiquette les lignes porteuses de prix
  (article / remise / total / paiement / bruit), guide le decodeur ;
- **tagger de roles** : quatorze roles sur toutes les lignes, designe
  l'enseigne, la ligne de date et les libelles d'articles.

| | asset | taille | sha256 |
|---|---|---|---|
| classifieur | \`$ASSET\` | $SIZE | \`$SHA\` |
| tagger | \`$TAGGER_ASSET\` | $TAGGER_SIZE | \`$TAGGER_SHA\` |

Recuperes au build par \`./tool/line_classifier/fetch.sh\`, epingles dans
\`tool/line_classifier/lock.env\`."

cat > tool/line_classifier/lock.env <<EOF
# Classifieur de lignes publie hors du depot, comme le modele quick-add : le
# fichier change a chaque reentrainement et gonflerait l'historique git.
# Versionne ici, il rend chaque commit reproductible — un vieux commit
# recupere le classifieur qu'il attend.
#
# Genere par tool/line_classifier/publish.sh, a ne pas editer a la main.
CLASSIFIER_REPOSITORY=$CLASSIFIER_REPOSITORY
CLASSIFIER_RELEASE=$RELEASE
CLASSIFIER_ASSET=$ASSET
CLASSIFIER_SHA256=$SHA
TAGGER_ASSET=$TAGGER_ASSET
TAGGER_SHA256=$TAGGER_SHA
EOF

echo
echo "Publie. Reste a committer :"
echo "  tool/line_classifier/lock.env  -> $RELEASE"
echo "Puis : flutter test"
