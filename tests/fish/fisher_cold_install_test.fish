#!/usr/bin/env fish
# Unit tests for cold-install fisher state — requires fisher install done.
# Run locally: make test-unit

set -g _chezmoi_src (chezmoi source-path 2>/dev/null)
set -g _chezmoiignore $_chezmoi_src/.chezmoiignore

source ~/.config/fish/conf.d/fisher_chezmoi_sync.fish 2>/dev/null

# ── all plugins from fish_plugins are installed ───────────────────────────────

@echo "fisher plugins installed"

set -l plugins (cat ~/.config/fish/fish_plugins | string trim | grep -v '^$')

for plugin in $plugins
    @test "$plugin: fisher tracks it" \
        (set -q _fisher_plugins && string match -q "*$plugin*" $_fisher_plugins && echo yes || echo no) = yes
end

# ── chezmoi add does not pick up fisher files ─────────────────────────────────

@echo "chezmoi add excludes fisher-managed files"

chezmoi add ~/.config/fish/functions 2>/dev/null
set -l after (chezmoi managed ~/.config/fish/functions 2>/dev/null | sort)

@test "__z.fish not added to chezmoi source" \
    (contains -- .config/fish/functions/__z.fish $after && echo yes || echo no) = no
