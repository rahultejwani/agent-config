# agent-config

Private devpod agent overlay: slim `AGENTS.md`, captain preferences, PR conventions, and automation to apply them on every devpod restart.

## Layout

| Path | Purpose |
|---|---|
| `AGENTS.md` | Slim always-on agent contract (~80 lines) |
| `captain.md` | Captain workflow preferences |
| `pr-conventions.md` | go-code / ARH / Linear PR rules |
| `claude-settings.json` | Claude Code defaults (Sonnet 1M, bypass permissions) |
| `bin/claude-primary.sh` | Claude launcher with devpod defaults |
| `setup.sh` | Idempotent apply script (run on every restart) |
| `devpod/rahul-agent.devpod.yaml` | Devpod preset — installs no-mistakes + applies config |

## Devpod setup (from laptop)

```bash
# One-time: register preset (paste contents of devpod/rahul-agent.devpod.yaml)
devpod config create-config rahul-agent --set-default

# Attach to existing devpod
devpod update rahultejwani -r virginia -c devpod/rahul-agent.devpod.yaml

# Or edit preset and push to all linked devpods
devpod config edit-config rahul-agent
```

New devpods:

```bash
devpod create my-pod --config-name rahul-agent -r virginia
```

## Manual apply (on devpod)

```bash
git clone git@github.uberinternal.com:rahul-tejwani_UBER/agent-config.git ~/agent-config
~/agent-config/setup.sh
```

## What gets applied

- `~/firstmate/AGENTS.md` and `CLAUDE.md` symlink
- `~/firstmate/data/captain.md` and `pr-conventions.md`
- `~/firstmate/bin/claude-primary.sh` on PATH
- `~/firstmate/.claude/settings.local.json` merged
- `~/.cursor/rules/agent.mdc` for Cursor sessions
- `no-mistakes` CLI installed or updated
