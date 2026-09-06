#!/usr/bin/env bash
# Recupere TOUS les modeles de l'app depuis les release assets GitHub.
#
#   ./tool/models/fetch.sh
#
# Telecharge la version epinglee dans tool/models/lock.env vers assets/models/
# et verifie chaque empreinte. Un modele absent ou corrompu ne casse pas le
# build — `assets/models/` est declare comme dossier dans pubspec.yaml — il
# casserait l'app chez l'utilisateur au premier ajout rapide ou au premier
# ticket scanne. D'ou l'echec ici, tot et bruyant.
#
# Un modele deja present sous une autre version mais d'empreinte identique est
# simplement renomme : reentrainer un seul modele fait avancer la version de
# tous, sans retelecharger les 142 Mo du quick-add pour autant.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source tool/models/registry.env
source tool/models/lock.env

checksum() {
  if command -v sha256sum > /dev/null; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

fetch_model() {
  local id="$1" pattern="$2"
  local upper asset expected destination glob url actual
  upper="$(echo "$id" | tr '[:lower:]' '[:upper:]')"
  asset="$(eval "echo \"\${${upper}_ASSET:-}\"")"
  expected="$(eval "echo \"\${${upper}_SHA256:-}\"")"
  if [ -z "$asset" ] || [ -z "$expected" ]; then
    echo "Modele $id absent de tool/models/lock.env" >&2
    exit 65
  fi

  destination="$ASSETS_DIR/$asset"
  glob="${pattern//%s/v*}"
  mkdir -p "$ASSETS_DIR"

  if [ -f "$destination" ] && [ "$(checksum "$destination")" = "$expected" ]; then
    echo "  $id : deja present et conforme ($asset)"
    return 0
  fi

  # Meme contenu sous un autre numero : la version a bouge pour un autre
  # modele, celui-ci n'a pas change.
  local candidate
  while IFS= read -r candidate; do
    [ -n "$candidate" ] || continue
    if [ "$(checksum "$candidate")" = "$expected" ]; then
      mv "$candidate" "$destination"
      echo "  $id : $(basename "$candidate") renomme en $asset (inchange)"
      return 0
    fi
  done < <(find "$ASSETS_DIR" -name "$glob")

  url="https://github.com/$REPOSITORY/releases/download/$RELEASE/$asset"
  echo "  $id : telechargement de $asset..."
  curl --fail --location --progress-bar --output "$destination.tmp" "$url"

  actual="$(checksum "$destination.tmp")"
  if [ "$actual" != "$expected" ]; then
    rm -f "$destination.tmp"
    echo "Empreinte inattendue pour $asset" >&2
    echo "  attendue : $expected" >&2
    echo "  obtenue  : $actual" >&2
    exit 1
  fi

  # Un seul exemplaire dans le manifeste : les anciens partent.
  find "$ASSETS_DIR" -name "$glob" ! -name "$asset" -delete
  mv "$destination.tmp" "$destination"
  echo "  $id : installe ($asset)"
}

echo "Modeles $RELEASE :"
for entry in "${MODELS[@]}"; do
  rest="${entry#*|}"
  fetch_model "${entry%%|*}" "${rest%%|*}"
done
