# no-mistakes personal fork

agent-config on **Uber internal GitHub** owns bootstrap and policy. The **no-mistakes code patch** lives on personal GitHub only.

## Split

| Asset | Location |
|---|---|
| AGENTS.md, setup.sh, devpod yaml, `no-mistakes/config.yaml` | `github.uberinternal.com/rahul-tejwani_UBER/agent-config` |
| Token-budget patch (until upstream merges) | `github.com/rahultejwani/no-mistakes` |

`setup.sh` reads `no-mistakes/fork.env` from the agent-config checkout. No home-directory file is required on devpod create/restart.

Optional local override: `~/.agent-config/no-mistakes-fork.env` (not in git).

## Devpod

On create/restart, devpod clones agent-config from Uber internal and runs `setup.sh`. That clones the public personal fork and runs `go build`. **github.com auth is not required** on the devpod unless the fork is private.

## Push changes to the no-mistakes fork

From a machine with personal GitHub auth:

```bash
gh auth login -h github.com   # once per machine
git -C ~/src/no-mistakes push origin main
```

Or from a separate clone:

```bash
git -C ~/no-mistakes push personal main
```

Fork URL: https://github.com/rahultejwani/no-mistakes

## Stay current with upstream

```bash
git -C ~/src/no-mistakes fetch upstream
git -C ~/src/no-mistakes merge upstream/main
git -C ~/src/no-mistakes push origin main
~/agent-config/setup.sh
```

Add upstream once if missing:

```bash
git -C ~/src/no-mistakes remote add upstream https://github.com/kunchenguid/no-mistakes.git
```

When upstream merges run-token-budget, remove `no-mistakes/fork.env` from agent-config and let setup fall back to the upstream release install.
