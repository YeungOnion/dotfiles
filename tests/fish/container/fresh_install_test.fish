#!/usr/bin/env fish
# Fresh-machine checks after `chezmoi init --apply` in the smoke container.
# Run: make test-smoke (invokes make test-container in the container)

@echo "guard: disposable container"

# Both signals required: the env var alone could leak into a host shell.
set -l in_container (set -q CHEZMOI_TEST_CONTAINER; and test -f /.dockerenv; and echo yes; or echo no)
@test "running inside the smoke container" \
    $in_container = yes
test $in_container = yes; or exit 1

# ── plugins installed from data ───────────────────────────────────────────────

@echo "fresh install: fish plugins from .chezmoidata.toml"

set -l data_plugins (chezmoi execute-template '{{ range .fish_plugins }}{{ . }}{{ "\n" }}{{ end }}')

@test "data lists plugins" \
    (count $data_plugins) -gt 0

for p in $data_plugins
    @test "$p installed by fisher" \
        (contains -- (string lower -- $p) (string lower -- $_fisher_plugins) && echo yes || echo no) = yes
end

@test "fish_plugins unchanged by fisher update" \
    (chezmoi diff --no-pager ~/.config/fish/fish_plugins </dev/null 2>&1 | count) = 0

@test "no pending chezmoi changes under ~/.config/fish" \
    (chezmoi status ~/.config/fish </dev/null 2>&1 | count) = 0

@test "retired sync hook not deployed" \
    (test -e ~/.config/fish/conf.d/fisher_chezmoi_sync.fish && echo yes || echo no) = no
