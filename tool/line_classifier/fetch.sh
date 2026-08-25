#!/usr/bin/env bash
# Recupere les modeles du scan (classifieur de lignes + tagger de roles)
# depuis les release assets GitHub.
#
#   ./tool/line_classifier/fetch.sh
#
# Sans argument, telecharge la version decrite par tool/line_classifier/lock.env
# dans assets/models/. Sort en erreur si l'empreinte ne correspond pas : un
# classifieur absent ou corrompu ne casse pas le build, il casserait le scan
# chez l'utilisateur au premier ticket.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT/tool/line_classifier/lock.env"

checksum() {
  if command -v sha256sum > /dev/null; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

fetch_artifact() {
  local asset="$1" expected="$2" pattern="$3"
  local destination="$ROOT/assets/models/$asset"
  local url="https://github.com/$CLASSIFIER_REPOSITORY/releases/download/$CLASSIFIER_RELEASE/$asset"

  if [ -f "$destination" ] && [ "$(checksum "$destination")" = "$expected" ]; then
    echo "Deja present et conforme : $asset"
    return 0
  fi

  echo "Telechargement de $asset depuis la release $CLASSIFIER_RELEASE..."
  mkdir -p "$(dirname "$destination")"
  curl --fail --location --progress-bar --output "$destination.tmp" "$url"

  local actual
  actual="$(checksum "$destination.tmp")"
  if [ "$actual" != "$expected" ]; then
    rm -f "$destination.tmp"
    echo "Empreinte inattendue pour $asset" >&2
    echo "  attendue : $expected" >&2
    echo "  obtenue  : $actual" >&2
    exit 1
  fi

  # Un seul exemplaire dans le manifeste : les anciens partent.
  find "$ROOT/assets/models" -name "$pattern" ! -name "$asset" -delete
  mv "$destination.tmp" "$destination"
  echo "Installe : assets/models/$asset"
}

fetch_artifact "$CLASSIFIER_ASSET" "$CLASSIFIER_SHA256" 'line_clf_v*.json'
fetch_artifact "$TAGGER_ASSET" "$TAGGER_SHA256" 'line_roles_v*.json' 
