#!/usr/bin/env fish
# fish PATH entries: shared ones in chezmoi data (fish.json fish_paths), machine-only
# ones in the local chezmoi config (fish_paths_local), rendered into config.fish.
# Run: fishtape tests/fish/fish_paths_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _tmpl $_repo_root/home/private_dot_config/private_fish/executable_config.fish.tmpl
set -g _cfg_tmpl $_repo_root/home/.chezmoi.toml.tmpl

@test "config.fish is a template" \
    (test -f $_tmpl; and echo yes; or echo no) = yes

@test "shared fish_paths are in data" \
    (jq -r '.fish_paths | length' $_repo_root/home/.chezmoidata/fish.json 2>/dev/null) = 5

set -l line (chezmoi execute-template < $_tmpl 2>/dev/null | string match -r '^\s*fish_add_path .*' | string trim)
for p in '$RUSTUP_HOME/bin' '$CARGO_HOME/bin' '$GOPATH/bin' '~/.local/bin' '~/.pixi/bin'
    @test "rendered fish_add_path includes $p" \
        (string match -q -- "* $p *" "$line "; and echo yes; or echo no) = yes
end

@test "local entries render single-quoted" \
    (chezmoi execute-template --override-data '{"fish_paths_local":["/opt/x y/bin"]}' < $_tmpl 2>/dev/null | string match -q "*'/opt/x y/bin'*"; and echo yes; or echo no) = yes

# a machine whose local config has no fish_paths_local
set -g _bare_cfg (mktemp --suffix .toml)
printf '[data]\n  java_home = ""\n' > $_bare_cfg
@test "renders without fish_paths_local" \
    (chezmoi --config $_bare_cfg execute-template < $_tmpl >/dev/null 2>&1; echo $status) = 0
trash $_bare_cfg

@test "chezmoi init keeps fish_paths_local" \
    (chezmoi execute-template --init --override-data '{"fish_paths_local":["/opt/x/bin"]}' < $_cfg_tmpl 2>/dev/null | string match -q '*fish_paths_local = ["/opt/x/bin"]*'; and echo yes; or echo no) = yes

@test "deployed config.fish matches chezmoi" \
    (chezmoi diff --no-pager ~/.config/fish/config.fish </dev/null 2>&1 | count) = 0
