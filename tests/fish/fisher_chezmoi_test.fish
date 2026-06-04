#!/usr/bin/env fish
# Tests for fisher/chezmoi ignore sync
# Run: fishtape tests/fish/fisher_chezmoi_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _chezmoi_src (chezmoi source-path 2>/dev/null)
set -g _chezmoiignore $_chezmoi_src/.chezmoiignore

source ~/.config/fish/conf.d/fisher_chezmoi_sync.fish 2>/dev/null

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

# ── sync: adds unmanaged files ────────────────────────────────────────────────

@echo "_fisher_sync_chezmoiignore: adds files not in chezmoi source"

set -l fake_fn ~/.config/fish/functions/_test_fisher_plugin.fish
echo "# fake fisher plugin for testing" > $fake_fn

@test "_fisher_sync_chezmoiignore returns 0" \
    (_fisher_sync_chezmoiignore; echo $status) = 0

set -l ignore_content (cat $_chezmoiignore 2>/dev/null)

@test "fisher:begin marker present" \
    (string match -q '*# fisher:begin*' "$ignore_content" && echo yes || echo no) = yes

@test "fisher:end marker present" \
    (string match -q '*# fisher:end*' "$ignore_content" && echo yes || echo no) = yes

@test "unmanaged function file added to ignore" \
    (grep -qF '.config/fish/functions/_test_fisher_plugin.fish' $_chezmoiignore && echo yes || echo no) = yes

# ── sync: removes stale entries ───────────────────────────────────────────────

@echo "_fisher_sync_chezmoiignore: removes entries for deleted files"

rm -f $fake_fn
_fisher_sync_chezmoiignore

@test "deleted file removed from ignore" \
    (grep -qF '.config/fish/functions/_test_fisher_plugin.fish' $_chezmoiignore && echo yes || echo no) = no

# ── sync: user-owned files stay out of ignore ─────────────────────────────────

@echo "_fisher_sync_chezmoiignore: chezmoi-managed files not in ignore block"

set -l ignore_block (awk '/^# fisher:begin/{p=1; next} /^# fisher:end/{p=0} p' $_chezmoiignore)

# __append_pipe_fzf.fish is chezmoi-managed (in source), so should not appear in the fisher block
@test "chezmoi-managed __append_pipe_fzf.fish not in fisher block" \
    (string match -q '*.config/fish/functions/__append_pipe_fzf.fish*' "$ignore_block" && echo yes || echo no) = no

# ── chezmoi add respects ignore entries ───────────────────────────────────────

@echo "chezmoi add: skips files in fisher ignore block"

set -l ignored_fn ~/.config/fish/functions/_chezmoi_add_test.fish
echo "# should be ignored by chezmoi add" > $ignored_fn

# Manually add it to the ignore so chezmoi add won't pick it up
echo ".config/fish/functions/_chezmoi_add_test.fish" >> $_chezmoiignore

chezmoi add ~/.config/fish/functions 2>/dev/null

@test "ignored file not added to chezmoi source" \
    (test -f "$_chezmoi_src/home/private_dot_config/private_fish/functions/_chezmoi_add_test.fish" && echo yes || echo no) = no

rm -f $ignored_fn
_fisher_sync_chezmoiignore
