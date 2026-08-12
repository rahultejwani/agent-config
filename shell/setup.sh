#!/usr/bin/env bash
# Idempotent devpod shell bootstrap: oh-my-zsh, powerlevel10k, fzf, op.
set -eu

CONFIG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SNIPPET="$CONFIG_ROOT/shell/agent-config.zsh"
SNIPPET_MARKER='agent-config/shell/agent-config.zsh'

log() { printf 'agent-config-shell: %s\n' "$*"; }

ensure_oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log "oh-my-zsh already installed"
    return 0
  fi
  log "installing oh-my-zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

ensure_powerlevel10k() {
  local theme_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [[ -d "$theme_dir" ]]; then
    log "powerlevel10k already installed"
    return 0
  fi
  [[ -d "$HOME/.oh-my-zsh" ]] || {
    log "oh-my-zsh is required before powerlevel10k"
    return 1
  }
  log "installing powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$theme_dir"
}

write_zsh_snippet() {
  cat > "$SNIPPET" << 'ZSH'
# Managed by agent-config/shell/setup.sh — do not edit by hand on devpod.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)

if [[ -d "$ZSH" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

if [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
fi
if [[ -f /usr/share/doc/fzf/examples/completion.zsh ]]; then
  source /usr/share/doc/fzf/examples/completion.zsh
fi

if command -v op >/dev/null 2>&1; then
  eval "$(op plugin init zsh)"
fi
ZSH
  log "wrote $SNIPPET"
}

wire_zshrc() {
  local rc="$HOME/.zshrc"
  [[ -f "$rc" ]] || touch "$rc"
  if grep -Fq "$SNIPPET_MARKER" "$rc"; then
    log "shell snippet already wired in .zshrc"
    return 0
  fi
  printf '\n# agent-config shell\nsource %s\n' "$SNIPPET" >> "$rc"
  log "wired shell snippet into .zshrc"
}

ensure_oh_my_zsh
ensure_powerlevel10k
write_zsh_snippet
wire_zshrc
log "shell setup complete"
