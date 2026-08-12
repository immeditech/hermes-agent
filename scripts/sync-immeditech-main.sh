#!/usr/bin/env bash
#
# sync-immeditech-main.sh
#
# Hält den Integrationsbranch `immeditech-main` aktuell:
#   1. spiegelt den Fork-main von upstream: main per Fast-Forward auf
#      upstream/main ziehen und nach origin/main pushen
#   2. merged origin/main in immeditech-main
#   3. merged jeden kuratierten Upstream-PR (siehe UPSTREAM_PRS) erneut rein
#
# Schritt 1 lief früher manuell (das Script setzte voraus, origin/main sei
# bereits gespiegelt) — jetzt erledigt es das selbst.
#
# Die PRs stammen aus NousResearch/hermes-agent und sind dort noch NICHT in
# main gemerged. Ist ein PR inzwischen upstream gelandet, ist sein Re-Merge ein
# No-op — dann darf (sollte) er aus der Liste entfernt werden.
#
# Strategie bewusst MERGE (kein Rebase): kein force-push nötig, Konflikte nur
# einmal lösen. Nach erfolgreichem Lauf: `git push origin immeditech-main`.
#
# Usage:
#   scripts/sync-immeditech-main.sh            # mit Mirror-Push nach origin/main
#   SKIP_MAIN_PUSH=1 scripts/sync-immeditech-main.sh   # nur lokal, kein Push
#
set -euo pipefail

# --- Kuratierte Upstream-PR-Nummern (NousResearch/hermes-agent) -------------
# Hier neue PRs ergänzen / erledigte entfernen.
# Erledigt & entfernt:
#   44700 → upstream gemerged via #54129 (rebased auf plugins/platforms/matrix/
#           adapter.py); #44700 selbst am 2026-06-28 als überholt geschlossen.
#   42300 → am 2026-07-05 wieder entfernt. Vaultwarden→Env degradiert VW zum
#           flachen Env-Beutel; ersetzt durch einen eigenen Broker
#           (immeditech/hermes-credential-broker). NICHT wieder aufnehmen.
#   47755 → am 2026-08-12 entfernt: upstream gemerged via #65610 (Salvage,
#           Autorschaft erhalten) + redirect_host aus #63889. Kommt seither
#           über den main-Mirror. ACHTUNG: upstream hat dabei umgebaut
#           (_make_redirect_handler-Closure statt functools.partial), unser
#           oauth.redirect_bind wurde beim Merge darauf neu aufgesetzt.
#
# Die Liste ist derzeit LEER — immeditech-main = upstream/main + nur noch
# unsere eigenen Patches (redirect_bind, HERMES_UPDATE_BRANCH, Devcontainer).
# Das ist der Zielzustand; neue Einträge bitte nur, wenn ein Upstream-PR
# wirklich unverzichtbar ist, bevor er dort gemerged wird.
UPSTREAM_PRS=()

ORIGIN_REMOTE="origin"      # immeditech/hermes-agent
UPSTREAM_REMOTE="upstream"  # NousResearch/hermes-agent
BRANCH="immeditech-main"
MAIN_BRANCH="main"
SKIP_MAIN_PUSH="${SKIP_MAIN_PUSH:-0}"   # =1 → Mirror nur lokal aktualisieren

cd "$(git rev-parse --show-toplevel)"

# upstream-Remote sicherstellen.
if ! git remote get-url "${UPSTREAM_REMOTE}" >/dev/null 2>&1; then
  echo "[sync] Lege Remote '${UPSTREAM_REMOTE}' an …"
  git remote add "${UPSTREAM_REMOTE}" https://github.com/NousResearch/hermes-agent.git
fi

echo "[sync] Fetch ${ORIGIN_REMOTE} + ${UPSTREAM_REMOTE} …"
git fetch "${ORIGIN_REMOTE}" main
git fetch "${UPSTREAM_REMOTE}" main

# --- Schritt 1: Fork-main von upstream spiegeln ----------------------------
# main muss ein reiner Mirror von upstream/main sein → Fast-Forward. Schlägt
# das fehl, hat main eigene Commits bekommen (sollte nicht passieren) und muss
# manuell bereinigt werden.
echo "[sync] Spiegele ${MAIN_BRANCH} ← ${UPSTREAM_REMOTE}/main …"
if git show-ref --verify --quiet "refs/heads/${MAIN_BRANCH}"; then
  git checkout "${MAIN_BRANCH}"
else
  git checkout -b "${MAIN_BRANCH}" "${ORIGIN_REMOTE}/main"
fi
if ! git merge --ff-only "${UPSTREAM_REMOTE}/main"; then
  echo "[sync] FEHLER: ${MAIN_BRANCH} lässt sich nicht fast-forwarden auf" \
       "${UPSTREAM_REMOTE}/main — der Fork-main ist abgewichen." >&2
  echo "[sync]        Bitte ${MAIN_BRANCH} manuell bereinigen und erneut laufen." >&2
  exit 1
fi
if [ "${SKIP_MAIN_PUSH}" = "1" ]; then
  echo "[sync] SKIP_MAIN_PUSH=1 → ${MAIN_BRANCH} wird nicht gepusht."
else
  echo "[sync] Push ${MAIN_BRANCH} → ${ORIGIN_REMOTE} …"
  git push "${ORIGIN_REMOTE}" "${MAIN_BRANCH}"
fi

# Branch auschecken (oder anlegen, falls noch nicht vorhanden).
if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  git checkout "${BRANCH}"
else
  git checkout -b "${BRANCH}" "${ORIGIN_REMOTE}/main"
fi

# Lokaler ${MAIN_BRANCH} ist nach Schritt 1 == upstream/main — den mergen wir
# (statt origin/main), damit es auch bei SKIP_MAIN_PUSH=1 korrekt ist.
echo "[sync] Merge ${MAIN_BRANCH} → ${BRANCH} …"
git merge --no-edit "${MAIN_BRANCH}"

# ${UPSTREAM_PRS[@]} auf einem leeren Array ist unter `set -u` in bash < 4.4
# ein Fehler (macOS-System-bash 3.2!) — daher die Längenprüfung davor.
if [ "${#UPSTREAM_PRS[@]}" -eq 0 ]; then
  echo "[sync] Keine kuratierten Upstream-PRs — nichts zu re-mergen."
fi
for pr in ${UPSTREAM_PRS[@]+"${UPSTREAM_PRS[@]}"}; do
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
