#!/usr/bin/env sh
# Treehouse post_create hook — seed and refresh sparse go-code BUILD files.
set -eu

if [ ! -x "./bin/git-bzl" ]; then
  exit 0
fi

printf 'treehouse-post-create: git-bzl setup in %s\n' "$(pwd)" >&2

if ./bin/git-bzl list >/dev/null 2>&1; then
  ./bin/git-bzl refresh
  exit 0
fi

gitdir=$(sed 's/gitdir: //' .git)
cache_root="${gitdir%/worktrees/*}"
wt_name=$(basename "$gitdir")
src_bzl="$cache_root/worktrees/go-code-sparse/bzl"
dst_bzl="$cache_root/worktrees/$wt_name/bzl"

if [ ! -d "$src_bzl" ]; then
  printf 'treehouse-post-create: no source bzl at %s; skipping refresh\n' "$src_bzl" >&2
  exit 0
fi

mkdir -p "$dst_bzl"
cp "$src_bzl"/* "$dst_bzl"/
./bin/git-bzl refresh
