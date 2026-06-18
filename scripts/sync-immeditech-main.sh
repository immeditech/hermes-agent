#!/usr/bin/env bash
#
# sync-immeditech-main.sh
#
# Hält den Integrationsbranch `immeditech-main` aktuell:
#   1. holt origin/main (= euer Fork-main, gespiegelt von NousResearch upstream)
#   2. merged origin/main in immeditech-main
#   3. merged jeden kuratierten Upstream-PR (siehe UPSTREAM_PRS) erneut rein
#
# Die PRs stammen aus NousResearch/hermes-agent und sind dort noch NICHT in
# main gemerged. Ist ein PR inzwischen upstream gelandet, ist sein Re-Merge ein
# No-op — dann darf (sollte) er aus der Liste entfernt werden.
#
# Strategie bewusst MERGE (kein Rebase): kein force-push nötig, Konflikte nur
# einmal lösen. Nach erfolgreichem Lauf: `git push origin immeditech-main`.
#
# Usage:
#   scripts/sync-immeditech-main.sh
#
set -euo pipefail

# --- Kuratierte Upstream-PR-Nummern (NousResearch/hermes-agent) -------------
# Hier neue PRs ergänzen / erledigte entfernen.
UPSTREAM_PRS=(
  44700  # fix(matrix): record DM rooms in m.direct on invite to prevent group misclassification
)

ORIGIN_REMOTE="origin"      # immeditech/hermes-agent
UPSTREAM_REMOTE="upstream"  # NousResearch/hermes-agent
BRANCH="immeditech-main"

cd "$(git rev-parse --show-toplevel)"

# upstream-Remote sicherstellen.
if ! git remote get-url "${UPSTREAM_REMOTE}" >/dev/null 2>&1; then
  echo "[sync] Lege Remote '${UPSTREAM_REMOTE}' an …"
  git remote add "${UPSTREAM_REMOTE}" https://github.com/NousResearch/hermes-agent.git
fi

echo "[sync] Fetch ${ORIGIN_REMOTE} + ${UPSTREAM_REMOTE} …"
git fetch "${ORIGIN_REMOTE}" main
git fetch "${UPSTREAM_REMOTE}" main

# Branch auschecken (oder anlegen, falls noch nicht vorhanden).
if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  git checkout "${BRANCH}"
else
  git checkout -b "${BRANCH}" "${ORIGIN_REMOTE}/main"
fi

echo "[sync] Merge ${ORIGIN_REMOTE}/main → ${BRANCH} …"
git merge --no-edit "${ORIGIN_REMOTE}/main"

for pr in "${UPSTREAM_PRS[@]}"; do
  echo "[sync] Hole + merge Upstream-PR #${pr} …"
  git fetch "${UPSTREAM_REMOTE}" "pull/${pr}/head"
  if git merge-base --is-ancestor FETCH_HEAD HEAD; then
    echo "[sync]   PR #${pr} ist bereits enthalten — übersprungen."
    continue
  fi
  git merge --no-ff --no-edit \
    -m "merge(upstream): NousResearch/hermes-agent#${pr}" FETCH_HEAD
done

echo
echo "[sync] Fertig. immeditech-main ist aktuell."
echo "[sync] Push: git push ${ORIGIN_REMOTE} ${BRANCH}"
