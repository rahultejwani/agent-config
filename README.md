# agent-config

Private devpod home for sahab's coding agents: slim `AGENTS.md`, preferences, PR conventions, and restart-safe bootstrap.

The git repo **is** the runtime home — there is no separate firstmate overlay.

## Layout

```
~/agent-config/
├── AGENTS.md              # Slim always-on agent contract
├── CLAUDE.md → AGENTS.md  # Created by setup.sh
├── sahab.md               # Workflow and delivery preferences
├── pr-conventions.md      # go-code / ARH / Linear PR rules
├── claude-settings.json   # Claude Code defaults template
├── bin/claude-primary.sh  # Launch Claude from this directory
├── setup.sh               # Idempotent bootstrap (every devpod restart)
├── devpod/                # Devpod preset YAML
└── cursor/agent.mdc       # Cursor rules (copied to ~/.cursor/rules/)
```

## Create the private repo (one-time)

The devpod token cannot create GitHub repos. Create an empty private repo, then push:

```bash
# https://github.uberinternal.com/new → name: agent-config → Private

git -C ~/agent-config remote add origin git@github.uberinternal.com:rahul-tejwani_UBER/agent-config.git
git -C ~/agent-config push -u origin main
```

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

- Installs or updates `no-mistakes`
- Symlinks `CLAUDE.md` → `AGENTS.md`
- Merges Claude settings into `.claude/settings.local.json`
- Installs `bin/claude` launcher on PATH
- Copies Cursor rules to `~/.cursor/rules/agent.mdc`
