# no-mistakes personal fork

agent-config installs your fork when `~/.agent-config/no-mistakes-fork.env` exists.
Until upstream merges the run-token-budget feature, the fork carries that patch.

## 1. Register personal GitHub on the devpod

This machine is logged into **github.uberinternal.com** only. Add **github.com**:

```bash
gh auth login -h github.com
```

Choose:

1. **GitHub.com** (not Enterprise)
2. **HTTPS** (no SSH keys on devpod by default)
3. **Login with a web browser** (or paste a personal access token)

Verify:

```bash
gh auth status -h github.com
gh api user --jq .login
```

Note your login (e.g. `rahultejwani`) for the fork URL below.

### Optional: token instead of browser

Create a classic PAT at https://github.com/settings/tokens with `repo` scope, then:

```bash
gh auth login -h github.com --with-token <<<"$GITHUB_TOKEN"
```

## 2. Fork on GitHub

In the browser: open https://github.com/kunchenguid/no-mistakes → **Fork** → your personal account.

Or from the devpod (after step 1):

```bash
gh repo fork kunchenguid/no-mistakes --remote=false --clone=false
```

## 3. Push the local patch to your fork

If you built the patch in `~/no-mistakes`:

```bash
GITHUB_USER="$(gh api user --jq .login)"
git -C ~/no-mistakes remote add personal "https://github.com/${GITHUB_USER}/no-mistakes.git" 2>/dev/null || true
git -C ~/no-mistakes push -u personal main
```

## 4. Point agent-config at the fork

```bash
cp ~/agent-config/no-mistakes/fork.env.example ~/.agent-config/no-mistakes-fork.env
# edit YOUR_GITHUB_USER → your login from step 1
~/agent-config/setup.sh
```

## 5. Stay current with upstream

```bash
git -C ~/src/no-mistakes remote add upstream https://github.com/kunchenguid/no-mistakes.git 2>/dev/null || true
git -C ~/src/no-mistakes fetch upstream
git -C ~/src/no-mistakes merge upstream/main
git -C ~/src/no-mistakes push origin main
~/agent-config/setup.sh   # rebuild binary
```

When upstream merges run-token-budget, drop the fork env file and use the stock install again.
