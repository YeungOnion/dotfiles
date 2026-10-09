#!/usr/bin/env fish
# zoxide replaces jethrokuan/z and keeps the `z` command.
# Run: fishtape tests/fish/zoxide_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _data $_repo_root/home/.chezmoidata

@test "zoxide is in brew_packages" \
    (jq -r '.brew_packages | index("zoxide") != null' $_data/packages.json) = true

@test "jethrokuan/z is no longer a fish plugin" \
    (jq -r '.fish_plugins | index("jethrokuan/z")' $_data/fish.json) = null

@test "zoxide conf.d is managed" \
    (test -f $_repo_root/home/private_dot_config/private_fish/conf.d/zoxide.fish; and echo yes; or echo no) = yes

@test "interactive fish defines z from zoxide" \
    (fish -i -c 'functions z' 2>/dev/null | string match -q '*__zoxide_z*'; and echo yes; or echo no) = yes

@test "zoxide has history (imported from z)" \
    (command -q zoxide; and test (zoxide query -l 2>/dev/null | count) -gt 0; and echo yes; or echo no) = yes
