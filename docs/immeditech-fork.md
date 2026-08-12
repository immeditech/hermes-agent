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
(Array `UPSTREAM_PRS`).

**Aktuell: keine.** Seit dem Sync am 2026-08-12 ist die Liste leer — alle drei
je kuratierten PRs sind erledigt:

| PR | Ausgang |
|----|---------|
| [#44700](https://github.com/NousResearch/hermes-agent/pull/44700) — fix(matrix): record DM rooms in m.direct | upstream gemerged via #54129 → entfernt 2026-07-04 |
| [#42300](https://github.com/NousResearch/hermes-agent/pull/42300) — feat(secrets): native Vaultwarden / `bw` | **gedroppt** 2026-07-05 (Fork-PR #1), ersetzt durch `immeditech/hermes-credential-broker`. Upstream hat das Feature am 2026-07-13 als `not_planned` geschlossen. **Nicht wieder aufnehmen.** |
| [#47755](https://github.com/NousResearch/hermes-agent/pull/47755) — fix(mcp-oauth): configurable `redirect_uri` | upstream gemerged via [#65610](https://github.com/NousResearch/hermes-agent/pull/65610) → entfernt 2026-08-12 |

## Eigene Patches (leben nur hier)

Das ist jetzt das **komplette** Delta gegenüber `upstream/main`:

| Was | Wo | Warum |
|-----|----|-------|
| `oauth.redirect_bind` | `tools/mcp_oauth.py`, Tests `TestRedirectBind` | Der OAuth-Callback-Listener bindet upstream **hart auf Loopback**. Unsere HAProxy steht auf einem *anderen* Host und kann den Loopback des Agent-LXC nicht erreichen. Opt-in, Default Loopback → rückwärtskompatibel. **Nicht** zu verwechseln mit upstreams `redirect_host` (#63889), das nur den Hostnamen in der *angekündigten* URI umschreibt. |
| `HERMES_UPDATE_BRANCH` | `hermes_cli/main.py` | `hermes update` ohne `--branch` soll unserem Fork-Branch folgen, nicht dem Upstream-Mirror `main`. Die Ansible-Rolle setzt die Variable in `~/.hermes/.env`. |
| Devcontainer + Sync-Skript + dieses Dok | `.devcontainer/`, `scripts/sync-immeditech-main.sh`, `docs/immeditech-fork.md` | Arbeitsumgebung und Sync-Mechanik |

Der `redirect_bind`-Patch ist als Upstream-PR vorgesehen — das Gate (Maintainer-Signal
auf #29299 **+** Merge von #47755) ist seit 2026-07-16 erfüllt. Stand und Argumentation:
`docs/11-mcp-oauth-redirect-bind.md` im Doku-Repo (`AgentSpace/hermes-workspace`).

> **Beim Merge beachten:** upstream hat mit #22161 eine **zweite Bindstelle**
> eingeführt (`_reserve_callback_port()` reserviert den Port schon bei der Auswahl).
> Unser Patch muss beide Stellen treffen, sonst binden Reservierung und HTTPServer
> auf verschiedene Interfaces. `TestRedirectBind::test_reserve_callback_port_honors_bind_host`
> ist der Regressionsschutz dafür.

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
