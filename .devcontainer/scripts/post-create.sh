#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Per-User-Claude-State persistent halten.
#
# Der Claude-State unter ~/.claude/ wird per Bind-Mount (./.claude im Repo)
# persistiert — siehe docker-compose.yaml. Der zusätzliche Per-User-State
# (OAuth-Token, Onboarding-State, MCP-Liste, Per-Projekt-State) lebt aber in
# ~/.claude.json direkt im Home und NICHT in ~/.claude/, wird vom Bind-Mount
# also nicht erfasst. Lösung: die echte Datei lebt im persistenten
# ~/.claude/.claude.json, ~/.claude.json ist nur ein Symlink darauf.
# ---------------------------------------------------------------------------
mkdir -p "${HOME}/.claude"
LIVE_CFG="${HOME}/.claude.json"
PERSIST_CFG="${HOME}/.claude/.claude.json"

if [ -f "${LIVE_CFG}" ] && [ ! -L "${LIVE_CFG}" ] && [ ! -f "${PERSIST_CFG}" ]; then
    mv "${LIVE_CFG}" "${PERSIST_CFG}"
fi
[ -f "${PERSIST_CFG}" ] || : > "${PERSIST_CFG}"
if [ ! -L "${LIVE_CFG}" ] || [ "$(readlink "${LIVE_CFG}")" != "${PERSIST_CFG}" ]; then
    if [ -f "${LIVE_CFG}" ] && [ ! -L "${LIVE_CFG}" ]; then
        mkdir -p "${HOME}/.claude/backups"
        cp "${LIVE_CFG}" "${HOME}/.claude/backups/.claude.json.recovered.$(date +%s)" || true
    fi
    rm -f "${LIVE_CFG}"
    ln -s "${PERSIST_CFG}" "${LIVE_CFG}"
fi

# ---------------------------------------------------------------------------
# Hermes-Dev-Umgebung bootstrappen (manuelle Clone-Variante aus CONTRIBUTING).
#
# uv legt das venv unter /workspace/.venv an (gitignored, vom Bind-Mount
# erfasst → überlebt Rebuilds). VS Code ist auf diesen Interpreter gezeigt
# (siehe devcontainer.json). Fehler hier sollen den Container-Start NICHT
# verhindern — schlägt der Install fehl (z. B. ohne Netz), kann man ihn
# manuell nachholen: `uv pip install -e ".[all,dev]"`.
# ---------------------------------------------------------------------------
cd /workspace

if [ ! -d /workspace/.venv ]; then
    echo "[post-create] Erstelle venv (.venv) mit uv …"
    uv venv .venv --python 3.13 || uv venv .venv
fi

export VIRTUAL_ENV="/workspace/.venv"
export PATH="/workspace/.venv/bin:${PATH}"

echo "[post-create] Installiere hermes-agent editierbar mit allen Extras (kann dauern) …"
if uv pip install -e ".[all,dev]"; then
    echo "[post-create] hermes-agent installiert."
else
    echo "[post-create] WARN: 'uv pip install -e .[all,dev]' fehlgeschlagen — bitte manuell nachholen." >&2
fi

# Optional: Browser-Tools / WhatsApp-Bridge brauchen die npm-Deps.
if [ -f /workspace/package.json ]; then
    npm install --no-audit --no-fund || echo "[post-create] WARN: npm install fehlgeschlagen (optional)." >&2
fi

# ---------------------------------------------------------------------------
# Hermes-Konfiguration für die Entwicklung vorbereiten (CONTRIBUTING.md).
# HERMES_HOME zeigt auf ~/.hermes (persistenter Bind-Mount).
# ---------------------------------------------------------------------------
HERMES_HOME="${HERMES_HOME:-${HOME}/.hermes}"
mkdir -p "${HERMES_HOME}"/{cron,sessions,logs,memories,skills}
if [ ! -f "${HERMES_HOME}/config.yaml" ] && [ -f /workspace/cli-config.yaml.example ]; then
    cp /workspace/cli-config.yaml.example "${HERMES_HOME}/config.yaml"
    echo "[post-create] ${HERMES_HOME}/config.yaml aus cli-config.yaml.example erstellt."
fi
[ -f "${HERMES_HOME}/.env" ] || : > "${HERMES_HOME}/.env"

echo "Hermes Agent Development Environment Ready!"
echo "→ venv: /workspace/.venv  |  CLI: ./hermes doctor"
echo "→ LLM-Key fehlt? In .devcontainer/.env oder ${HERMES_HOME}/.env eintragen (z. B. OPENROUTER_API_KEY=…)."
