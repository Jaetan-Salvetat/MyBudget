#!/usr/bin/env bash
# Publie un modele quick-add : tokenizer regenere, asset versionne, release
# GitHub, lock mis a jour.
#
#   ./tool/publish_model.sh            # version suivante d'apres tool/model.lock
#   ./tool/publish_model.sh v5         # version imposee
#
# Sources par defaut : ml/quick_add/output/model.onnx et
# ml/quick_add/output/best/tokenizer.json, surchargeables par MODEL_SOURCE et
# TOKENIZER_SOURCE. Sans sortie d'entrainement, publie le modele deja depose
# dans assets/models/.
#
# Rien n'est a editer a la main ensuite : QuickAddModelRunner lit le nom du
# modele dans le manifeste des assets, et tool/model.lock est reecrit ici.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

source tool/model.lock

MODEL_SOURCE="${MODEL_SOURCE:-ml/quick_add/output/model.onnx}"
TOKENIZER_SOURCE="${TOKENIZER_SOURCE:-ml/quick_add/output/best/tokenizer.json}"
TOKENIZER_ASSET="assets/models/tokenizer.bin"

if [ $# -gt 1 ]; then
  echo "usage: ./tool/publish_model.sh [version]" >&2
  exit 64
fi

if [ $# -eq 1 ]; then
  VERSION="$1"
else
  CURRENT="${MODEL_ASSET#model_v}"
  VERSION="v$((${CURRENT%.onnx} + 1))"
fi

ASSET="model_$VERSION.onnx"
DESTINATION="assets/models/$ASSET"
RELEASE="model-$VERSION"

command -v gh > /dev/null || { echo "gh est requis" >&2; exit 69; }

# Republier sous un tag existant laisserait les installations deja a jour sur
# l'ancien modele — le cache du plugin ONNX est indexe par nom de fichier.
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

if [ -f "$MODEL_SOURCE" ]; then
  if [ -f "$TOKENIZER_SOURCE" ]; then
    echo "Regeneration de $TOKENIZER_ASSET..."
    dart run tool/build_tokenizer_asset.dart "$TOKENIZER_SOURCE" "$TOKENIZER_ASSET"
  else
    echo "Tokenizer source absent ($TOKENIZER_SOURCE), $TOKENIZER_ASSET inchange."
  fi

  # Le manifeste ne doit contenir qu'un modele : le runner refuse de choisir.
  find assets/models -name 'model_v*.onnx' -delete
  cp "$MODEL_SOURCE" "$DESTINATION"
elif [ -f "$DESTINATION" ]; then
  echo "Pas de sortie d'entrainement, publication de $DESTINATION tel quel."
else
  echo "Ni $MODEL_SOURCE ni $DESTINATION : rien a publier." >&2
  exit 66
fi

SHA="$(checksum "$DESTINATION")"

RELEASE_FILES=("$DESTINATION")
# La source HuggingFace est archivee avec le modele : elle ne vit plus dans le
# depot, et c'est elle qui permet de regenerer le tokenizer binaire.
[ -f "$TOKENIZER_SOURCE" ] && RELEASE_FILES+=("$TOKENIZER_SOURCE")

echo "Publication de $RELEASE..."
gh release create "$RELEASE" "${RELEASE_FILES[@]}" \
  --title "Quick-add model $VERSION" \
  --notes "Modèle ONNX de l'ajout rapide.

| | |
|---|---|
| asset | \`$ASSET\` |
| sha256 | \`$SHA\` |

Récupéré au build par \`./tool/fetch_model.sh\`, épinglé dans \`tool/model.lock\`."

cat > tool/model.lock <<EOF
# Modele quick-add publie hors du depot : LFS facture le stockage et la bande
# passante a chaque run de CI, les release assets non. Fichier lu par
# tool/fetch_model.sh et par le cache de la CI — versionne dans git, il rend
# chaque commit reproductible : un vieux commit recupere le modele qu'il attend.
#
# Genere par tool/publish_model.sh, a ne pas editer a la main.
MODEL_REPOSITORY=$MODEL_REPOSITORY
MODEL_RELEASE=$RELEASE
MODEL_ASSET=$ASSET
MODEL_SHA256=$SHA
EOF

echo
echo "Publie. Reste a committer :"
echo "  tool/model.lock       -> $RELEASE"
echo "  $TOKENIZER_ASSET  -> regenere si le tokenizer source etait present"
echo "Puis : flutter test (le golden verifie l'encodage du tokenizer)"
