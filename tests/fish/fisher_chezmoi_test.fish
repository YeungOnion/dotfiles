#!/usr/bin/env fish
# Read-only checks for fisher/chezmoi ignore state on the live home.
# Sync behavior (which writes files) lives in tests/fish/container/.
# Run: fishtape tests/fish/fisher_chezmoi_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _chezmoi_src (chezmoi source-path 2>/dev/null)
set -g _chezmoiignore $_chezmoi_src/.chezmoiignore

# ── shell health ──────────────────────────────────────────────────────────────

@echo "shell health"

set -l _stderr (fish -c exit 2>&1)
@test "fish starts without stderr" \
    (count $_stderr) = 0

# ── structure after chezmoi apply ────────────────────────────────────────────

@echo "chezmoi apply: expected files present"

@test "fish_plugins deployed to target" \
    (test -f ~/.config/fish/fish_plugins && echo yes || echo no) = yes

@test "fisher_chezmoi_sync conf.d deployed" \
    (test -f ~/.config/fish/conf.d/fisher_chezmoi_sync.fish && echo yes || echo no) = yes

@test "chezmoi source-path resolves" \
    (test -n "$_chezmoi_src" && echo yes || echo no) = yes

# ── ignore file shape ─────────────────────────────────────────────────────────

@echo ".chezmoiignore: fisher block"

set -l ignore_content (cat $_chezmoiignore 2>/dev/null)

@test "fisher:begin marker present" \
    (string match -q '*# fisher:begin*' "$ignore_content" && echo yes || echo no) = yes

@test "fisher:end marker present" \
    (string match -q '*# fisher:end*' "$ignore_content" && echo yes || echo no) = yes

set -l ignore_block (awk '/^# fisher:begin/{p=1; next} /^# fisher:end/{p=0} p' $_chezmoiignore)

# __append_pipe_fzf.fish is chezmoi-managed (in source), so should not appear in the fisher block
@test "chezmoi-managed __append_pipe_fzf.fish not in fisher block" \
    (string match -q '*.config/fish/functions/__append_pipe_fzf.fish*' "$ignore_block" && echo yes || echo no) = no

@test "no duplicate lines in .chezmoiignore" \
    (sort $_chezmoiignore | uniq -d | count) = 0
