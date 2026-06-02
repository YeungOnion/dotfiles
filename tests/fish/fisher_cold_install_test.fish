#!/usr/bin/env fish
# Cold install integration tests — run against the integration image only
# Requires: docker build -f Dockerfile.integration -t chezmoi-integration .
# Run: fishtape tests/fish/fisher_cold_install_test.fish

set -g _chezmoi_src (chezmoi source-path 2>/dev/null)
set -g _chezmoiignore $_chezmoi_src/.chezmoiignore

source ~/.config/fish/conf.d/fisher_chezmoi_sync.fish 2>/dev/null

# ── shell starts clean ────────────────────────────────────────────────────────

@echo "shell health after cold install"

set -l _stderr (fish -c exit 2>&1)
@test "fish starts without stderr" \
    (count $_stderr) = 0

# ── all plugins from fish_plugins are installed ───────────────────────────────

@echo "fisher plugins installed"

set -l plugins (cat ~/.config/fish/fish_plugins | string trim | grep -v '^$')

for plugin in $plugins
    set -l name (string split -r -m1 / $plugin)[-1]
    @test "$plugin: fisher tracks it" \
        (set -q _fisher_plugins && string match -q "*$plugin*" $_fisher_plugins && echo yes || echo no) = yes
end

# ── chezmoiignore populated with real plugin files ────────────────────────────

@echo "chezmoiignore populated after install"

@test "fisher:begin block exists" \
    (grep -qF '# fisher:begin' $_chezmoiignore && echo yes || echo no) = yes

@test "fisher block is non-empty" \
    (awk '/^# fisher:begin/{p=1;next} /^# fisher:end/{p=0} p && NF' $_chezmoiignore | wc -l | string trim \
        | string match -r '^[1-9]' | count) = 1

# ── chezmoi add does not pick up fisher files ─────────────────────────────────

@echo "chezmoi add excludes fisher-managed files"

# Snapshot source before
set -l before (chezmoi managed ~/.config/fish/functions 2>/dev/null | sort)

# Add the whole functions dir — should only pick up user files
chezmoi add ~/.config/fish/functions 2>/dev/null

set -l after (chezmoi managed ~/.config/fish/functions 2>/dev/null | sort)

# z plugin installs __z.fish — a representative fisher-managed file
@test "__z.fish not added to chezmoi source" \
    (contains -- .config/fish/functions/__z.fish $after && echo yes || echo no) = no

# ── user-owned files are still reachable ─────────────────────────────────────

@echo "user-owned config intact"

@test "aliases.fish deployed" \
    (test -f ~/.config/fish/aliases.fish && echo yes || echo no) = yes

@test "config.fish deployed" \
    (test -f ~/.config/fish/config.fish && echo yes || echo no) = yes

@test "user function __append_pipe_fzf.fish not in fisher ignore block" \
    (awk '/^# fisher:begin/{p=1;next} /^# fisher:end/{p=0} p' $_chezmoiignore \
        | grep -qF '__append_pipe_fzf.fish' && echo yes || echo no) = no
