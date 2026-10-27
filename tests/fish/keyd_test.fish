#!/usr/bin/env fish
# keyd: Caps Lock is Ctrl when chorded and Esc when tapped; the script that installs it
# renders only on native Linux, never under WSL.
# Run: fishtape tests/fish/keyd_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _src $_repo_root/home
set -g _script $_src/.chezmoiscripts/run_onchange_after_08-keyd.sh.tmpl

set -g _tmp
set -g _bare_cfg (mktemp --suffix .toml)
set -ga _tmp $_bare_cfg
printf '[data]\n  java_home = ""\n' > $_bare_cfg

function _render --description 'render the script with data JSON $argv[1]'
    chezmoi --config $_bare_cfg --source $_src execute-template --override-data $argv[1] < $_script
end

set -g _linux '{"chezmoi":{"os":"linux","kernel":{"osrelease":"7.0.0-38-generic"}}}'
set -g _wsl '{"chezmoi":{"os":"linux","kernel":{"osrelease":"5.15.167.4-microsoft-standard-WSL2"}}}'
set -g _wsl1 '{"chezmoi":{"os":"linux","kernel":{"osrelease":"4.4.0-19041-Microsoft"}}}'
set -g _darwin '{"chezmoi":{"os":"darwin","kernel":{"osrelease":"24.0.0"}}}'

@echo "script renders only on native linux"

@test "native linux renders content" \
    (_render $_linux | string trim | string length -q; and echo content; or echo empty) = content

@test "WSL2 renders empty" \
    (_render $_wsl | string trim | string length -q; and echo content; or echo empty) = empty

@test "WSL1 (capital Microsoft) renders empty" \
    (_render $_wsl1 | string trim | string length -q; and echo content; or echo empty) = empty

@test "darwin renders empty" \
    (_render $_darwin | string trim | string length -q; and echo content; or echo empty) = empty

@echo "config content"

@test "default tap threshold is 200 ms" \
    (_render $_linux | string match -q '*capslock = overloadt(control, esc, 200)*'; and echo yes; or echo no) = yes

@test "keyd_tap_ms overrides the threshold" \
    (_render '{"keyd_tap_ms":300,"chezmoi":{"os":"linux","kernel":{"osrelease":"7.0.0-38-generic"}}}' \
        | string match -q '*capslock = overloadt(control, esc, 300)*'; and echo yes; or echo no) = yes

@test "script finds the Debian binary name keyd.rvaiya" \
    (_render $_linux | string match -q '*command -v keyd.rvaiya*'; and echo yes; or echo no) = yes

@test "script reloads through the found binary, not a bare keyd" \
    (_render $_linux | string match -q '*sudo "$(find_keyd)" reload*'; and echo yes; or echo no) = yes

@test "script passes bash syntax check" \
    (_render $_linux | bash -n; echo $status) = 0

trash $_tmp
