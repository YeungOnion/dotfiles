#!/usr/bin/env fish
# Unit tests for cold-install fisher state — requires fisher install done.
# Run locally: make test-unit

set -g _chezmoi_src (chezmoi source-path 2>/dev/null)
set -g _chezmoiignore $_chezmoi_src/.chezmoiignore

# ── all plugins from fish_plugins are installed ───────────────────────────────

@echo "fisher plugins installed"

set -l plugins (cat ~/.config/fish/fish_plugins | string trim | grep -v '^$')

for plugin in $plugins
    @test "$plugin: fisher tracks it" \
        (set -q _fisher_plugins && string match -q "*$plugin*" $_fisher_plugins && echo yes || echo no) = yes
end

# ── chezmoi add would not pick up fisher files ────────────────────────────────

@echo "chezmoi add excludes fisher-managed files"

# Read-only: --dry-run reports "warning: ignoring <rel>" per ignored path and
# writes nothing. --no-pager and closed stdin keep a large diff from blocking.
# `chezmoi ignored` is not usable here: it lists nothing for target-only files.
# fish has no wildcard variable expansion: enumerate fisher's per-plugin file lists
set -l fisher_files
for var in (set -n | string match '_fisher_*_files')
    set -a fisher_files (string replace -r '^~' $HOME $$var)
end
set -l ignored (chezmoi add --dry-run --verbose --no-pager $fisher_files </dev/null 2>&1 \
    | string replace -rf '^chezmoi: warning: ignoring ' '')

@test "fisher recorded installed files" \
    (count $fisher_files) -gt 0

for f in $fisher_files
    set -l rel (string replace -- "$HOME/" "" $f)
    @test "$rel ignored by chezmoi add" \
        (contains -- $rel $ignored && echo yes || echo no) = yes
end
