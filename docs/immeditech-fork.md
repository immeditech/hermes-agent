# Immeditech-Fork: `immeditech-main`

Dieser Fork (`immeditech/hermes-agent`, Remote `origin`) spiegelt den Upstream
`NousResearch/hermes-agent` (Remote `upstream`). Der Branch **`immeditech-main`**
ist ein **Integrationsbranch**: er folgt `main` und trägt zusätzlich einige
Upstream-PRs, die dort noch nicht in `main` gemerged sind.

## Remotes

| Remote     | Repo                              | Zweck                          |
|------------|-----------------------------------|--------------------------------|
| `origin`   | `immeditech/hermes-agent`         | euer Fork (`main`, `immeditech-main`) |
| `upstream` | `NousResearch/hermes-agent`       | Quelle der kuratierten PRs     |

`main` wird unverändert vom Upstream gehalten — dort nichts committen.
Eigene Anpassungen (Devcontainer, dieser Doc, das Sync-Skript) und die
kuratierten PRs leben auf `immeditech-main`.

## Kuratierte PRs

Die Liste der reingemergten Upstream-PRs ist die **einzige Wahrheitsquelle** im
Sync-Skript: [`scripts/sync-immeditech-main.sh`](../scripts/sync-immeditech-main.sh)
(Array `UPSTREAM_PRS`). Aktuell:

- [#44700](https://github.com/NousResearch/hermes-agent/pull/44700) — fix(matrix): record DM rooms in m.direct on invite

## Aktualisieren (wenn `main` sich bewegt)

```bash
scripts/sync-immeditech-main.sh
git push origin immeditech-main
```

Das Skript holt `origin/main` + `upstream/main`, merged `main` in
`immeditech-main` und merged anschließend jeden Pr aus `UPSTREAM_PRS` erneut
(bereits enthaltene PRs werden übersprungen). Strategie ist **Merge** (kein
Rebase): kein force-push, Konflikte nur einmal lösen.

### Neuen PR aufnehmen

1. PR-Nummer ins Array `UPSTREAM_PRS` in `scripts/sync-immeditech-main.sh` eintragen
   (mit Kommentar = PR-Titel) und hier in der Liste oben ergänzen.
2. `scripts/sync-immeditech-main.sh` laufen lassen.

### Erledigten PR entfernen

Sobald ein PR upstream in `main` gelandet ist, ist sein Re-Merge ein No-op.
Eintrag aus `UPSTREAM_PRS` (und aus der Liste oben) entfernen, um die Liste
schlank zu halten.

## Lokal entwickeln (Devcontainer)

Siehe [`.devcontainer/`](../.devcontainer/). Kurz:

```bash
cp .devcontainer/.env.example .devcontainer/.env   # Keys/Identität eintragen
# VS Code: „Reopen in Container"
```

Der Container bringt `uv`, Python, Node, Claude Code und die Immeditech-CA mit;
`post-create.sh` legt das venv (`.venv`) an, installiert `hermes-agent` mit
allen Extras und bereitet `~/.hermes` vor. Danach im Container z. B.:

```bash
./hermes doctor
./hermes chat -q "Hello"
```
