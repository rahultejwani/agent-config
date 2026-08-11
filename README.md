# agent-config

Private devpod home for sahab's coding agents: slim `AGENTS.md`, preferences, PR conventions, and restart-safe bootstrap.

The git repo **is** the runtime home — there is no separate firstmate overlay.

## Repo layout

| Repo | Host | Role |
|---|---|---|
| **agent-config** | [github.com/rahultejwani/agent-config-](https://github.com/rahultejwani/agent-config-) | Source of truth — policy, bootstrap, devpod preset |
| **no-mistakes** (fork) | [github.com/rahultejwani/no-mistakes](https://github.com/rahultejwani/no-mistakes) | Patched binary only (run token budget until upstream merges) |

```
~/agent-config/
├── AGENTS.md              # Slim always-on agent contract
├── CLAUDE.md → AGENTS.md  # Created by setup.sh
├── sahab.md               # Workflow and delivery preferences
├── pr-conventions.md      # go-code / ARH / Linear PR rules
├── no-mistakes/
│   ├── config.yaml        # Managed ~/.no-mistakes defaults (4h CI, 500k budget)
│   └── fork.env           # Pointer to personal no-mistakes fork
├── setup.sh               # Idempotent bootstrap (every devpod restart)
├── devpod/                # Devpod preset YAML
└── cursor/agent.mdc       # Cursor rules (copied to ~/.cursor/rules/)
```

## Devpod boot flow

On **create** and **restart**:

1. Devpod clones/updates **agent-config** from [github.com/rahultejwani/agent-config-](https://github.com/rahultejwani/agent-config-).
2. `setup.sh` reads `no-mistakes/fork.env`, clones `github.com/rahultejwani/no-mistakes` to `~/src/no-mistakes`, and builds the binary.
3. Managed policy merges into `~/.no-mistakes/config.yaml`.
4. Claude launcher, Cursor rules, and PATH are applied.

Personal **github.com** auth on the devpod is required once to clone the private agent-config repo (`gh auth login -h github.com`). The no-mistakes fork is public and needs no auth to clone.

## Devpod preset (from laptop)

```bash
devpod config create-config rahul-agent --set-default
# paste devpod/rahul-agent.devpod.yaml

devpod update rahultejwani -r virginia -c devpod/rahul-agent.devpod.yaml
```

New devpods: `devpod create my-pod --config-name rahul-agent -r virginia`

## Daily use

```bash
cd ~/agent-config
claude          # or bin/claude-primary.sh
```

## What setup.sh does on every restart

- Builds `no-mistakes` from the personal fork (`no-mistakes/fork.env`)
- Applies managed defaults to `~/.no-mistakes/config.yaml`
- Symlinks `CLAUDE.md` → `AGENTS.md`
- Merges Claude settings into `.claude/settings.local.json`
- Installs `bin/claude` launcher on PATH
- Copies Cursor rules to `~/.cursor/rules/agent.mdc`

Optional override: `~/.agent-config/no-mistakes-fork.env` overrides the repo `fork.env` without editing git.

## no-mistakes fork maintenance

See [docs/no-mistakes-fork.md](docs/no-mistakes-fork.md) for syncing with upstream and pushing fork updates.
