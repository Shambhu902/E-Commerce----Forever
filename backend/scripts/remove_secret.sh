#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || true)
if [ -z "$REPO_ROOT" ]; then
  echo "Error: run this script from inside a git repository."
  exit 1
fi

SECRET_PATH="backend/.env"
PUSH=false

usage() {
  cat <<EOF
Usage: $0 [--push] [--path PATH]

This script safely removes a file from git history using git-filter-repo.

Options:
  --push        After rewriting history, push changes to origin with --force-with-lease
  --path PATH   Path to the file to remove from history (default: backend/.env)

IMPORTANT: Rotate any exposed secrets (e.g., Stripe keys) before or immediately after
running this. The script creates a backup branch and will not push unless you pass --push.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --push) PUSH=true; shift ;;
    --path) SECRET_PATH="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

echo "Repository root: $REPO_ROOT"
echo "Target path to remove: $SECRET_PATH"

read -rp "Type YES to continue (this will rewrite git history locally): " CONFIRM
if [ "$CONFIRM" != "YES" ]; then
  echo "Aborted by user."
  exit 1
fi

if ! command -v git-filter-repo >/dev/null 2>&1; then
  echo "git-filter-repo is not installed. Install with: pip3 install git-filter-repo"
  exit 1
fi

ts=$(date +%Y%m%d%H%M%S)
backup_branch="backup-main-$ts"
echo "Creating backup branch $backup_branch"
git branch "$backup_branch"

# Ensure .gitignore contains the secret path
if ! grep -qxF "$SECRET_PATH" .gitignore 2>/dev/null; then
  echo "$SECRET_PATH" >> .gitignore
  git add .gitignore || true
  git commit -m "Ignore $SECRET_PATH" || true
fi

# Create .env.example by stripping values if file exists
if [ -f "$SECRET_PATH" ]; then
  echo "Creating ${SECRET_PATH}.example with REDACTED values"
  mkdir -p "$(dirname "$SECRET_PATH")"
  awk -F'=' '{ if (NF>1) print $1"=REDACTED"; else print $0 }' "$SECRET_PATH" > "${SECRET_PATH}.example"
  git add "${SECRET_PATH}.example" || true
  git commit -m "Add ${SECRET_PATH}.example without secrets" || true
fi

echo "Running git-filter-repo to remove $SECRET_PATH from history..."
git filter-repo --invert-paths --path "$SECRET_PATH" --force

echo "History rewritten locally. Verify the repo state and logs now." 
git --no-pager log --decorate --oneline -n 5

if [ "$PUSH" = true ]; then
  echo "About to force-push rewritten history to origin/main."
  read -rp "Type PUSH to proceed with force-push: " PUSHCONFIRM
  if [ "$PUSHCONFIRM" = "PUSH" ]; then
    git push --force-with-lease origin main
    git push --force-with-lease --tags origin
    echo "Force-push completed."
  else
    echo "Push aborted by user. You must push manually when ready."
  fi
else
  echo "Push not requested. To push your cleaned history, run:" 
  echo "  git push --force-with-lease origin main"
  echo "  git push --force-with-lease --tags origin"
fi

echo "Done. Remember to rotate any exposed credentials immediately."
