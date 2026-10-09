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

@test "chezmoi source-path resolves" \
    (test -n "$_chezmoi_src" && echo yes || echo no) = yes

# ── plugin list is chezmoi data ───────────────────────────────────────────────

@echo "fish_plugins: rendered from .chezmoidata/fish.json"

@test "fish_plugins data renders the deployed plugin list" \
    "$(chezmoi execute-template '{{ range .fish_plugins }}{{ . }}{{ "\n" }}{{ end }}' 2>&1)" = "$(cat ~/.config/fish/fish_plugins)"

@test "fish_plugins has no pending chezmoi diff" \
    (chezmoi diff --no-pager ~/.config/fish/fish_plugins </dev/null 2>&1 | count) = 0

set -l _plugins_script $_chezmoi_src/.chezmoiscripts/run_onchange_after_06-fish-plugins.sh.tmpl

@test "fish-plugins script renders fisher update" \
    (chezmoi execute-template < $_plugins_script 2>/dev/null | string match -q 'fisher update'; and echo yes; or echo no) = yes

# test -f first: `bash -n` on empty stdin succeeds, which would pass vacuously
@test "fish-plugins script passes bash syntax check" \
    (test -f $_plugins_script; and chezmoi execute-template < $_plugins_script 2>/dev/null | bash -n; and echo yes; or echo no) = yes

# Run the rendered fish heredoc with fisher stubbed: `fisher update` exits 0 even
# when a download fails, so the script itself must notice a missing plugin.
set -l _plugins_fish (chezmoi execute-template < $_plugins_script 2>/dev/null | sed -n "/<<'FISH'/,/^FISH\$/p" | sed '1d;$d' | string collect)
set -l _data_plugins (chezmoi execute-template '{{ range .fish_plugins }}{{ . }}{{ "\n" }}{{ end }}')

@test "fish-plugins script fails when a listed plugin is missing" \
    (fish --no-config -c "function fisher; end; set -g _fisher_plugins jorgebucaran/fisher; $_plugins_fish" >/dev/null 2>&1; echo $status) = 1

@test "fish-plugins script succeeds when every listed plugin is installed" \
    (fish --no-config -c "function fisher; end; set -g _fisher_plugins \$argv; $_plugins_fish" $_data_plugins >/dev/null 2>&1; echo $status) = 0

@test "fish-plugins bootstrap fails fast when curl fails" \
    (string match -q '*curl -fsSL*' < $_plugins_script; and string match -q '*functions -q fisher; or exit 1*' < $_plugins_script; and echo yes; or echo no) = yes

set -l _install_script $_chezmoi_src/.chezmoiscripts/run_onchange_02-install-packages.sh.tmpl
@test "install-packages script no longer touches fisher" \
    (test -f $_install_script; and not string match -q '*fisher*' < $_install_script; and echo clean; or echo dirty) = clean

# ── ignore rendered from fisher state ─────────────────────────────────────────

@echo ".chezmoiignore: rendered from fisher's record"

set -l _ignore_tmpl $_chezmoi_src/.chezmoiignore
set -l rendered (chezmoi execute-template < $_ignore_tmpl 2>/dev/null)

@test "retired sync hook not deployed" \
    (test -e ~/.config/fish/conf.d/fisher_chezmoi_sync.fish && echo yes || echo no) = no

@test "ignore template has no fisher:begin marker" \
    (test -f $_ignore_tmpl; and not string match -q '*fisher:begin*' < $_ignore_tmpl; and echo clean; or echo dirty) = clean

@test "rendered ignore lists a fisher-owned file" \
    (contains -- .config/fish/functions/__z.fish $rendered && echo yes || echo no) = yes

@test "rendered ignore lists static non-fisher entries" \
    (contains -- .config/fish/completions/swamp.fish $rendered && echo yes || echo no) = yes

@test "rendered ignore omits chezmoi-managed __append_pipe_fzf.fish" \
    (contains -- .config/fish/functions/__append_pipe_fzf.fish $rendered && echo yes || echo no) = no

@test "rendered ignore has no duplicate entries" \
    (printf '%s\n' $rendered | sort | uniq -d | count) = 0

# Fresh machine: fish not on PATH yet → only static lines, no error
set -l _chezmoi_bin (command -v chezmoi)
# PATH minus every directory holding a fish executable, wherever fish lives
set -l _no_fish_path
for dir in $PATH
    test -x $dir/fish; or set -a _no_fish_path $dir
end
set -l no_fish (env PATH=(string join : $_no_fish_path) $_chezmoi_bin execute-template < $_ignore_tmpl 2>&1; echo "status=$status")

@test "filtered PATH really has no fish" \
    (env PATH=(string join : $_no_fish_path) sh -c 'command -v fish' >/dev/null; and echo found; or echo none) = none

@test "renders without fish on PATH" \
    $no_fish[-1] = status=0

@test "without fish on PATH no fisher entries render" \
    (contains -- .config/fish/functions/__z.fish $no_fish && echo yes || echo no) = no

# fish present but fisher never ran → empty universal scope, still no error
set -l _empty_xdg (mktemp -d)
set -l no_fisher (env XDG_CONFIG_HOME=$_empty_xdg $_chezmoi_bin --config ~/.config/chezmoi/chezmoi.toml execute-template < $_ignore_tmpl 2>&1; echo "status=$status")
trash $_empty_xdg

@test "renders with empty fish universal scope" \
    $no_fisher[-1] = status=0

@test "with empty universal scope no fisher entries render" \
    (contains -- .config/fish/functions/__z.fish $no_fisher && echo yes || echo no) = no

# Stray stdout from fish config must not become an ignore pattern
set -l _stray_xdg (mktemp -d)
mkdir -p $_stray_xdg/fish/conf.d
echo "echo '*'" > $_stray_xdg/fish/conf.d/stray.fish
set -l with_stray (env XDG_CONFIG_HOME=$_stray_xdg $_chezmoi_bin --config ~/.config/chezmoi/chezmoi.toml execute-template < $_ignore_tmpl 2>/dev/null)
trash $_stray_xdg

@test "stray fish stdout is not an ignore pattern" \
    (contains -- '*' $with_stray && echo leaked || echo filtered) = filtered
