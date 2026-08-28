#!/usr/bin/env bash
# Publie les donnees du scan dans les release assets GitHub.
#
#   ./tool/scan_data/publish.sh                         # ce qui a change
#   ./tool/scan_data/publish.sh annotations [version]   # ~12 Mo, souvent
#   ./tool/scan_data/publish.sh images      [version]   # ~4,6 Go, rarement
#
# Sans argument, le script hache le contenu des deux corpus et ne publie que
# celui dont l'empreinte a bouge. Hacher 4,6 Go coute ~8 s (SHA-256 accelere
# par le materiel), la ou reconstruire et reenvoyer l'archive coute des
# minutes : la detection se paie, la republication inutile non.
#
# L'empreinte porte sur le CONTENU (chemin + hachage de chaque fichier), pas
# sur l'archive : un tar.gz embarque les mtimes, donc reecrire des fichiers a
# contenu identique changerait son sha sans que rien n'ait bouge.
#
# Deux charges, deux cadences, deux releases — mais UN SEUL lock.env, reecrit
# en entier par ce script a chaque fois. C'est ce qui empeche les pointeurs de
# diverger en silence : on ne peut pas oublier de bumper un fichier qu'on
# n'edite jamais a la main.
#
# Pourquoi separer : le corpus annote se republie a chaque evolution du prompt
# ou du format, les images presque jamais. Les empaqueter ensemble ferait
# reenvoyer 4,6 Go pour 12 Mo de changement.
#
# Pourquoi archiver les images plutot que de les retelecharger : `open_prices`
# est un jeu VIVANT, son dump grossit chaque jour et ses contributeurs peuvent
# supprimer une preuve. Un re-fetch ne rend donc pas le meme corpus, et les
# annotations pointeraient vers des images absentes. Ce qu'on archive, c'est
# le corpus DEJA TRIE : selection FR, nommage stable, verite externe a cote.
#
# Ne sont pas archives : `synthetic` (regenere a l'identique, seed 42) et les
# selections FindIt derivees (corpus/rebuild.py). Voir fetch_data.sh.
#
# Pourquoi le corpus annote sort du depot, alors que c'est une verite : il est
# reecrit EN BLOC a chaque passe, et git garde un blob neuf par fichier. Le
# golden FindIt, lui, reste versionne — cure a la main, stable, irremplacable.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

source tool/scan_data/lock.env

CORPUS_DIR="ml/scan/data/corpus"
ANNOTATIONS_DIR="ml/scan/data/annotations"
IMAGE_SOURCES=("photos_pixel" "open_prices" "mixed")
# GitHub refuse un asset de plus de 2 Gio : les images partent en morceaux.
PART_SIZE="1500m"

WHAT="${1-}"
case "$WHAT" in
  annotations|images) shift ;;
  "") ;;
  *)
    echo "usage: ./tool/scan_data/publish.sh [{annotations|images} [version]]" >&2
    exit 64
    ;;
esac

command -v gh > /dev/null || { echo "gh est requis" >&2; exit 69; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if command -v sha256sum > /dev/null; then
  HASH_CMD=(sha256sum)
else
  HASH_CMD=(shasum -a 256)
fi

checksum() {
  "${HASH_CMD[@]}" | cut -d' ' -f1
}

# L'empreinte du CONTENU d'un corpus : le hachage de chaque fichier et son
# chemin, triés puis rehachés. Insensible aux mtimes, donc reecrire des
# fichiers a contenu identique ne la fait pas bouger.
manifest() {
  find "$@" -type f -exec "${HASH_CMD[@]}" {} + | sort | checksum
}

next_version() {
  local current="$1"
  echo "v$(( ${current##*-v} + 1 ))"
}

write_lock() {
  cat > tool/scan_data/lock.env <<EOF
# Donnees du scan publiees hors du depot : des Go de photos que LFS
# facturerait a chaque checkout de CI, et un corpus annote reecrit en bloc a
# chaque evolution du prompt ou du format. Versionne ici, ce fichier rend
# chaque commit reproductible — un vieux commit recupere les donnees sur
# lesquelles il a ete mesure.
#
# Les deux charges ont leur propre cadence, donc leur propre release. Ce
# fichier est reecrit en entier par tool/scan_data/publish.sh : ne pas
# l'editer a la main.
SCAN_DATA_REPOSITORY=$SCAN_DATA_REPOSITORY
ANNOTATIONS_RELEASE=$ANNOTATIONS_RELEASE
ANNOTATIONS_ASSET=$ANNOTATIONS_ASSET
ANNOTATIONS_SHA256=$ANNOTATIONS_SHA256
ANNOTATIONS_MANIFEST=$ANNOTATIONS_MANIFEST
IMAGES_RELEASE=$IMAGES_RELEASE
IMAGES_ASSETS="$IMAGES_ASSETS"
IMAGES_SHA256=$IMAGES_SHA256
IMAGES_MANIFEST=$IMAGES_MANIFEST
EOF
}

publish_annotations() {
  local version="${1:-$(next_version "$ANNOTATIONS_RELEASE")}"
  local release="scan-annotations-$version"
  local asset="scan-annotations-$version.tar.gz"

  gh release view "$release" > /dev/null 2>&1 &&
    { echo "La release $release existe deja." >&2; exit 1; }
  [ -d "$ANNOTATIONS_DIR" ] || { echo "Corpus annote absent" >&2; exit 66; }

  echo "Archivage du corpus annote..."
  tar -czf "$WORK/$asset" -C "$(dirname "$ANNOTATIONS_DIR")" "$(basename "$ANNOTATIONS_DIR")"
  local sha size tickets corpora
  sha="$(checksum < "$WORK/$asset")"
  size="$(du -h "$WORK/$asset" | cut -f1)"
  tickets="$(find "$ANNOTATIONS_DIR" -name '*.json' | wc -l | tr -d ' ')"
  corpora="$(find "$ANNOTATIONS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | paste -sd', ' -)"

  echo "Publication de $release ($tickets tickets, $size)..."
  gh release create "$release" "$WORK/$asset" \
    --title "Corpus annote scan $version" \
    --notes "Tickets annotes ligne a ligne : la supervision du tagger de roles.

| | |
|---|---|
| asset | \`$asset\` |
| tickets | $tickets |
| corpus | $corpora |
| taille | $size |
| sha256 | \`$sha\` |

Cette archive **suffit a entrainer** : chaque enregistrement porte les lignes
physiques, leurs mots et leur geometrie. Les images ne servent qu'a
re-annoter. Le filtre d'acceptation n'est pas stocke, il est rejoue au
chargement.

Recupere par \`./tool/scan_data/fetch.sh --annotations\`."

  ANNOTATIONS_RELEASE="$release"
  ANNOTATIONS_ASSET="$asset"
  ANNOTATIONS_SHA256="$sha"
  ANNOTATIONS_MANIFEST="$(manifest "$ANNOTATIONS_DIR")"
  write_lock
  echo
  echo "Publie. Reste a committer : tool/scan_data/lock.env -> $release"
}

publish_images() {
  local version="${1:-$(next_version "$IMAGES_RELEASE")}"
  local release="scan-images-$version"
  local prefix="scan-images-$version.tar.gz."

  gh release view "$release" > /dev/null 2>&1 &&
    { echo "La release $release existe deja." >&2; exit 1; }
  for source in "${IMAGE_SOURCES[@]}"; do
    [ -d "$CORPUS_DIR/$source" ] || { echo "Corpus absent : $CORPUS_DIR/$source" >&2; exit 66; }
  done

  echo "Archivage de ${IMAGE_SOURCES[*]} (decoupe a $PART_SIZE)..."
  tar -czf - -C "$CORPUS_DIR" "${IMAGE_SOURCES[@]}" | split -a 2 -b "$PART_SIZE" - "$WORK/$prefix"

  local parts assets sha size images
  parts=("$WORK/$prefix"??)
  assets="$(for part in "${parts[@]}"; do basename "$part"; done | paste -sd' ' -)"
  sha="$(cat "${parts[@]}" | checksum)"
  size="$(du -ch "${parts[@]}" | tail -1 | cut -f1)"
  images="$(find "${IMAGE_SOURCES[@]/#/$CORPUS_DIR/}" -type f \( -name '*.jpg' -o -name '*.png' \) | wc -l | tr -d ' ')"

  echo "Publication de $release ($images images, $size, ${#parts[@]} morceaux)..."
  gh release create "$release" "${parts[@]}" \
    --title "Images scan $version" \
    --notes "Le corpus d'images **deja trie** : selection francaise, nommage
stable, verite externe a cote sous \`open_prices/truth/\`.

| | |
|---|---|
| images | $images |
| corpus | ${IMAGE_SOURCES[*]} |
| taille | $size en ${#parts[@]} morceaux |
| sha256 | \`$sha\` (flux reconstitue) |

Decoupe parce que GitHub refuse un asset de plus de 2 Gio. \`fetch.sh\`
reassemble les morceaux avant de verifier l'empreinte.

Archive et non retelecharge : \`open_prices\` est un jeu vivant dont le dump
grossit chaque jour et dont les contributeurs peuvent supprimer une preuve.
Un re-fetch ne rendrait pas le meme corpus.

Ne sont pas ici : \`synthetic\` (regenere seed 42) et les selections FindIt
derivees. \`ml/scan/research/fetch_data.sh\` les reconstruit.

Recupere par \`./tool/scan_data/fetch.sh\`."

  IMAGES_RELEASE="$release"
  IMAGES_ASSETS="$assets"
  IMAGES_SHA256="$sha"
  IMAGES_MANIFEST="$(manifest "${IMAGE_SOURCES[@]/#/$CORPUS_DIR/}")"
  write_lock
  echo
  echo "Publie. Reste a committer : tool/scan_data/lock.env -> $release"
}

case "$WHAT" in
  annotations) publish_annotations "$@" ;;
  images) publish_images "$@" ;;
  "")
    echo "Empreinte du corpus annote..."
    if [ "$(manifest "$ANNOTATIONS_DIR")" = "$ANNOTATIONS_MANIFEST" ]; then
      echo "  inchange, rien a publier ($ANNOTATIONS_RELEASE)"
    else
      publish_annotations
    fi
    echo "Empreinte des images..."
    if [ "$(manifest "${IMAGE_SOURCES[@]/#/$CORPUS_DIR/}")" = "$IMAGES_MANIFEST" ]; then
      echo "  inchangees, rien a publier ($IMAGES_RELEASE)"
    else
      publish_images
    fi
    ;;
esac
