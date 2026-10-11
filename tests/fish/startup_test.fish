#!/usr/bin/env fish
# fish startup layout: config.fish owns setup in line order (environment, Homebrew,
# declarative PATH, tool hooks); conf.d holds only self-contained snippets.
# Run: fishtape tests/fish/startup_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _fish_src $_repo_root/home/private_dot_config/private_fish
set -g _rendered (chezmoi execute-template < $_fish_src/executable_config.fish.tmpl 2>/dev/null)

function _line --description 'first line number in rendered config.fish matching a regex'
    for i in (seq (count $_rendered))
        if string match -qr -- $argv[1] $_rendered[$i]
            echo $i
            return
        end
    end
    # 'none' makes a numeric comparison fail instead of passing vacuously
    echo none
end

@echo "config.fish owns setup, in order"

for pat in 'brew shellenv' 'fish_add_path --global --path' 'mise activate' 'direnv hook' 'zoxide init'
    @test "config.fish runs: $pat" \
        (count (string match -r -- $pat $_rendered)) -gt 0
end

@test "Homebrew before PATH entries" \
    (test (_line "brew shellenv") -lt (_line "fish_add_path --global"); and echo yes; or echo no) = yes
@test "PATH entries before tool hooks" \
    (test (_line 'fish_add_path --global') -lt (_line 'mise activate'); and echo yes; or echo no) = yes

@echo "conf.d holds no tool setup"

for f in 00-path.fish 00-path.fish.tmpl mise.fish direnv.fish zoxide.fish
    @test "conf.d/$f is not in source" \
        (test -e $_fish_src/conf.d/$f; and echo present; or echo absent) = absent
end

@test "zoxide's old conf.d file is retired via .chezmoiremove" \
    (string match -q '.config/fish/conf.d/zoxide.fish' < $_repo_root/home/.chezmoiremove; and echo yes; or echo no) = yes

@echo "this machine"

@test "interactive startup prints nothing" \
    (fish -i -c exit 2>&1 | count) = 0

@test "mise is activated" \
    (fish -i -c 'functions -q __mise_env_eval; and echo yes; or echo no' 2>/dev/null) = yes

@echo "fresh machine: no saved fish state, bare PATH"

set -g _fresh (mktemp -d)
cp -r ~/.config/fish $_fresh/fish
command rm -f $_fresh/fish/fish_variables
set -g _fish_bin (command -s fish)
function _fresh_fish
    env -i HOME=$HOME USER=$USER TERM=xterm-256color PATH=/usr/bin:/bin XDG_CONFIG_HOME=$_fresh $_fish_bin -i -c $argv[1] 2>/dev/null
end

@test "fresh shell has Homebrew on PATH" \
    (_fresh_fish 'command -q brew; and echo yes; or echo no') = yes
@test "fresh shell has the shared PATH entries" \
    (_fresh_fish 'contains $CARGO_HOME/bin $PATH; and contains ~/.local/bin $PATH; and echo yes; or echo no') = yes
@test "fresh shell activates mise" \
    (_fresh_fish 'functions -q __mise_env_eval; and echo yes; or echo no') = yes
@test "fresh shell defines z from zoxide" \
    (_fresh_fish 'functions -q __zoxide_z; and echo yes; or echo no') = yes
@test "startup saves no fish_user_paths (PATH stays declarative)" \
    (string match -q '*fish_user_paths*' < $_fresh/fish/fish_variables 2>/dev/null; and echo saved; or echo none) = none

trash $_fresh
