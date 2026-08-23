#!/usr/bin/env bash
# Recupere le modele quick-add depuis les release assets GitHub.
#
# Le fichier n'est pas dans le depot : 142 Mo par version, que LFS facturerait
# en stockage et en bande passante a chaque checkout de CI.
#
#   ./tool/fetch_model.sh
#
# Sans argument, telecharge la version decrite par tool/model.lock dans
# assets/models/. Sort en erreur si l'empreinte ne correspond pas : un modele
# absent ou corrompu ne casse pas le build, il casserait l'app chez
# l'utilisateur au premier ajout rapide.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT/tool/model.lock"

DESTINATION="$ROOT/assets/models/$MODEL_ASSET"
URL="https://github.com/$MODEL_REPOSITORY/releases/download/$MODEL_RELEASE/$MODEL_ASSET"

checksum() {
  if command -v sha256sum > /dev/null; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

if [ -f "$DESTINATION" ] && [ "$(checksum "$DESTINATION")" = "$MODEL_SHA256" ]; then
  echo "Modele deja present et conforme : $MODEL_ASSET"
  exit 0
fi

echo "Telechargement de $MODEL_ASSET depuis la release $MODEL_RELEASE..."
mkdir -p "$(dirname "$DESTINATION")"
curl --fail --location --progress-bar --output "$DESTINATION.tmp" "$URL"

ACTUAL="$(checksum "$DESTINATION.tmp")"
if [ "$ACTUAL" != "$MODEL_SHA256" ]; then
  rm -f "$DESTINATION.tmp"
  echo "Empreinte inattendue pour $MODEL_ASSET" >&2
  echo "  attendue : $MODEL_SHA256" >&2
  echo "  obtenue  : $ACTUAL" >&2
  exit 1
fi

mv "$DESTINATION.tmp" "$DESTINATION"
echo "Modele installe : assets/models/$MODEL_ASSET"
