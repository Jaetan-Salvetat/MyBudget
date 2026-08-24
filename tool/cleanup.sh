#!/usr/bin/env bash
# Supprime les artefacts d'entrainement devenus inutiles dans ml/.
#
#   ./tool/cleanup.sh                 # ce qui serait supprime
#   ./tool/cleanup.sh --apply         # a la fin d'un entrainement
#   ./tool/cleanup.sh --min-free 50 --apply   # en cours de run, disque plein
#
# L'etat cible est celui decrit par ml/README.md : output/best, un model.onnx a
# jour, dataset/entities.jsonl et dataset/cache. Tout le reste se regenere.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ML_DIR="${ML_ROOT:-$ROOT/ml}"
HF_CACHE_DIR="${ML_HF_CACHE_DIR:-$HOME/.cache/huggingface/hub}"

LEVEL_REGENERABLE=1
LEVEL_STALE=2
LEVEL_DERIVED=3
LEVEL_BACKUP=4
LEVEL_REDOWNLOADABLE=5

CACHE_DIR_NAMES=(__pycache__ .pytest_cache .ruff_cache .mypy_cache)
SKIPPED_TREES=(.venv .git node_modules)
EXPORT_NAMES=(model.onnx model.onnx.data)
DERIVED_DATASETS=(train.jsonl eval.jsonl)
TRAINING_PROCESS_PATTERN='python.*train\.py'

apply=0
keep_checkpoints=0
with_datasets=0
with_backups=0
with_hf_cache=0
min_free_gb=0
project=""

usage() {
  cat <<'EOF'
tool/cleanup.sh [projet] — supprime les artefacts d'entrainement inutiles.

Sans argument, tous les projets de ml/ sont traites.

  --apply                supprime reellement (defaut : simulation)
  --keep-checkpoints N   conserve les N checkpoints trainer les plus recents
  --datasets             inclut train.jsonl / eval.jsonl (regenerables depuis entities.jsonl)
  --backups              inclut les sauvegardes de runs precedents (output/best_*)
  --hf-cache             inclut le cache huggingface du backbone
  --min-free GO          s'arrete des que cet espace libre est atteint
  -h, --help             affiche cette aide

Jamais touches : output/best, output/model.onnx a jour, dataset/entities.jsonl,
dataset/cache, .venv. Les checkpoints sont epargnes si un entrainement tourne.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --apply) apply=1 ;;
    --keep-checkpoints) keep_checkpoints="$2"; shift ;;
    --datasets) with_datasets=1 ;;
    --backups) with_backups=1 ;;
    --hf-cache) with_hf_cache=1 ;;
    --min-free) min_free_gb="$2"; shift ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "option inconnue : $1" >&2; usage >&2; exit 2 ;;
    *) project="$1" ;;
  esac
  shift
done

projects() {
  local path
  if [ -n "$project" ]; then
    printf '%s\n' "$ML_DIR/$project"
    return 0
  fi
  for path in "$ML_DIR"/*/; do
    printf '%s\n' "${path%/}"
  done
}

if [ -n "$project" ] && [ ! -d "$ML_DIR/$project" ]; then
  echo "projet inconnu : $project" >&2
  exit 2
fi

candidates="$(mktemp)"
trap 'rm -f "$candidates"' EXIT

size_kb() {
  du -sk "$1" 2>/dev/null | awk '{print $1}'
}

free_kb() {
  df -Pk "$ML_DIR" | awk 'NR == 2 {print $4}'
}

mtime() {
  stat -f %m "$1" 2>/dev/null || stat -c %Y "$1"
}

human() {
  awk -v kb="$1" 'BEGIN { printf "%.2f Go", kb / 1048576 }'
}

training_is_running() {
  pgrep -f "$TRAINING_PROCESS_PATTERN" >/dev/null 2>&1
}

add_candidate() {
  local level="$1" reason="$2" path="$3"
  [ -e "$path" ] || return 0
  printf '%s\t%s\t%s\t%s\n' "$level" "$(size_kb "$path")" "$reason" "$path" >>"$candidates"
}

collect_python_caches() {
  local project_dir="$1"
  local prune=() name
  [ -d "$project_dir" ] || return 0
  for name in "${SKIPPED_TREES[@]}"; do
    prune+=(-name "$name" -o)
  done
  find "$project_dir" \( "${prune[@]}" -false \) -prune -o -type d \( \
    -name "${CACHE_DIR_NAMES[0]}" -o -name "${CACHE_DIR_NAMES[1]}" \
    -o -name "${CACHE_DIR_NAMES[2]}" -o -name "${CACHE_DIR_NAMES[3]}" \
    \) -print | while IFS= read -r path; do
    add_candidate "$LEVEL_REGENERABLE" "cache python" "$path"
  done
  return 0
}

collect_trainer_checkpoints() {
  local output_dir="$1"
  [ -d "$output_dir" ] || return 0
  local steps=() path step total droppable index
  while IFS= read -r path; do
    step="${path##*/checkpoint-}"
    [[ "$step" =~ ^[0-9]+$ ]] || continue
    steps+=("$step	$path")
  done < <(find "$output_dir" -maxdepth 1 -type d -name 'checkpoint-*')
  total="${#steps[@]}"
  droppable=$((total - keep_checkpoints))
  [ "$droppable" -gt 0 ] || return 0
  index=0
  while IFS=$'\t' read -r step path; do
    [ "$index" -lt "$droppable" ] || break
    add_candidate "$LEVEL_STALE" "checkpoint trainer (reprise de run)" "$path"
    index=$((index + 1))
  done < <(printf '%s\n' "${steps[@]}" | sort -n -k1,1)
  return 0
}

collect_stale_exports() {
  local output_dir="$1"
  local weights="$output_dir/best/model.safetensors" artefact name
  [ -f "$weights" ] || return 0
  for name in "${EXPORT_NAMES[@]}"; do
    artefact="$output_dir/$name"
    [ -f "$artefact" ] || continue
    if [ "$(mtime "$artefact")" -lt "$(mtime "$weights")" ]; then
      add_candidate "$LEVEL_STALE" "export onnx perime" "$artefact"
    fi
  done
  return 0
}

collect_derived_datasets() {
  local dataset_dir="$1"
  local name
  for name in "${DERIVED_DATASETS[@]}"; do
    add_candidate "$LEVEL_DERIVED" "split regenerable (generate_dataset.py)" "$dataset_dir/$name"
  done
  return 0
}

collect_run_backups() {
  local output_dir="$1"
  [ -d "$output_dir" ] || return 0
  find "$output_dir" -maxdepth 1 -type d -name 'best_*' |
    while IFS= read -r path; do
      add_candidate "$LEVEL_BACKUP" "sauvegarde d'un run precedent" "$path"
    done
  return 0
}

collect_hf_cache() {
  [ -d "$HF_CACHE_DIR" ] || return 0
  find "$HF_CACHE_DIR" -maxdepth 1 -mindepth 1 -type d |
    while IFS= read -r path; do
      add_candidate "$LEVEL_REDOWNLOADABLE" "cache huggingface" "$path"
    done
  return 0
}

training_running=0
if training_is_running; then
  training_running=1
  echo "entrainement en cours : checkpoints conserves"
fi

while IFS= read -r project_dir; do
  collect_python_caches "$project_dir"
  collect_stale_exports "$project_dir/output"
  if [ "$training_running" -eq 0 ]; then
    collect_trainer_checkpoints "$project_dir/output"
  fi
  if [ "$with_datasets" -eq 1 ]; then
    collect_derived_datasets "$project_dir/dataset"
  fi
  if [ "$with_backups" -eq 1 ]; then
    collect_run_backups "$project_dir/output"
  fi
done < <(projects)

if [ "$with_hf_cache" -eq 1 ]; then
  collect_hf_cache
fi

target_kb="$(awk -v gb="$min_free_gb" 'BEGIN { printf "%d", gb * 1048576 }')"
available_kb="$(free_kb)"
plan="$(mktemp)"
trap 'rm -f "$candidates" "$plan"' EXIT

sort -t "$(printf '\t')" -k1,1n -k2,2nr "$candidates" |
  awk -F '\t' -v target="$target_kb" -v available="$available_kb" '
    target > 0 && available + freed >= target { exit }
    { freed += $2; print }
  ' >"$plan"

if [ ! -s "$plan" ]; then
  echo "rien a supprimer ($(human "$available_kb") libres)"
  exit 0
fi

total_kb=0
while IFS=$(printf '\t') read -r _ kb reason path; do
  printf '%10s  %-38s %s\n' "$(human "$kb")" "$reason" "$path"
  total_kb=$((total_kb + kb))
done <"$plan"

if [ "$apply" -eq 0 ]; then
  printf '\nsimulation : %s recuperables (--apply pour supprimer)\n' "$(human "$total_kb")"
  exit 0
fi

cut -f4 <"$plan" | while IFS= read -r path; do
  rm -rf "$path"
done

printf '\nsupprime : %s — espace libre : %s\n' "$(human "$total_kb")" "$(human "$(free_kb)")"
