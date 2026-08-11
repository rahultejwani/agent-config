#!/usr/bin/env bash
# Build no-mistakes from a personal GitHub fork (source install).
set -eu

NO_MISTAKES_SRC="${NO_MISTAKES_SRC:-$HOME/src/no-mistakes}"
NO_MISTAKES_FORK_BRANCH="${NO_MISTAKES_FORK_BRANCH:-main}"
INSTALL_DIR="${NO_MISTAKES_INSTALL_DIR:-$HOME/.local/bin}"

if [[ -z "${NO_MISTAKES_FORK:-}" ]]; then
  echo "install-no-mistakes-fork: NO_MISTAKES_FORK is unset" >&2
  exit 1
fi

command -v go >/dev/null 2>&1 || {
  echo "install-no-mistakes-fork: go is required" >&2
  exit 1
}

mkdir -p "$(dirname "$NO_MISTAKES_SRC")" "$INSTALL_DIR"

if [[ ! -d "$NO_MISTAKES_SRC/.git" ]]; then
  git clone --branch "$NO_MISTAKES_FORK_BRANCH" "$NO_MISTAKES_FORK" "$NO_MISTAKES_SRC"
else
  git -C "$NO_MISTAKES_SRC" fetch origin
  git -C "$NO_MISTAKES_SRC" checkout "$NO_MISTAKES_FORK_BRANCH"
  git -C "$NO_MISTAKES_SRC" pull --ff-only origin "$NO_MISTAKES_FORK_BRANCH"
fi

git -C "$NO_MISTAKES_SRC" remote add upstream https://github.com/kunchenguid/no-mistakes.git 2>/dev/null || true

( cd "$NO_MISTAKES_SRC" && go build -o "$INSTALL_DIR/no-mistakes" ./cmd/no-mistakes )

command -v no-mistakes >/dev/null 2>&1 || {
  echo "install-no-mistakes-fork: build failed" >&2
  exit 1
}

echo "install-no-mistakes-fork: installed $(no-mistakes version 2>/dev/null || echo built) to $INSTALL_DIR/no-mistakes"
