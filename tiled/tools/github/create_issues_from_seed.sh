#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./tools/github/create_issues_from_seed.sh [repo] [seed_file]
# Example:
#   ./tools/github/create_issues_from_seed.sh LittleCogWorks/tiled ../tiled-docs/github-issues/issues-seed.tsv

REPO="${1:-LittleCogWorks/tiled}"
SEED_FILE="${2:-../tiled-docs/github-issues/issues-seed.tsv}"
DRY_RUN="${DRY_RUN:-1}"

if [[ ! -f "$SEED_FILE" ]]; then
  echo "Seed file not found: $SEED_FILE"
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is not installed or not on PATH in this shell."
  echo "Install from: https://cli.github.com/"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "You are not authenticated with gh. Run: gh auth login"
  exit 1
fi

created=0
skipped=0

while IFS='|' read -r title labels summary acceptance; do
  [[ -z "${title// }" ]] && continue
  [[ "$title" =~ ^# ]] && continue

  # Skip duplicates by exact title
  if gh issue list --repo "$REPO" --state all --search "\"$title\" in:title" --limit 100 --json title | grep -Fq "\"title\":\"$title\""; then
    echo "[skip] Issue already exists: $title"
    skipped=$((skipped + 1))
    continue
  fi

  body=$(cat <<EOF
## Summary
$summary

## Acceptance criteria
- $acceptance

## Notes
- Imported from local planning board.
EOF
)

  label_args=()
  IFS=',' read -ra parts <<< "$labels"
  for raw in "${parts[@]}"; do
    label="$(echo "$raw" | xargs)"
    if [[ -n "$label" ]]; then
      label_args+=(--label "$label")
    fi
  done

  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[dry-run] gh issue create --repo $REPO --title \"$title\" ${label_args[*]} --body <body>"
  else
    gh issue create --repo "$REPO" --title "$title" "${label_args[@]}" --body "$body"
    echo "[create] $title"
  fi

  created=$((created + 1))
done < "$SEED_FILE"

echo "Done. processed=$((created + skipped)) created=$created skipped=$skipped dry_run=$DRY_RUN"