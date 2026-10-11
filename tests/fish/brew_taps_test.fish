#!/usr/bin/env fish
# Homebrew taps: chezmoi init asks once per tap in brew_tap_packages and stores the answer
# in the local config; script 02 installs only formulas from trusted taps.
# Run: fishtape tests/fish/brew_taps_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _cfg_tmpl $_repo_root/home/.chezmoi.toml.tmpl
set -g _install $_repo_root/home/.chezmoiscripts/run_onchange_02-install-packages.sh.tmpl

set -g _tmp
# a bare config, so this machine's own answers never leak into these renders
set -g _bare_cfg (mktemp --suffix .toml)
set -ga _tmp $_bare_cfg
printf '[data]\n  java_home = ""\n' > $_bare_cfg

function _src --description 'temp source dir whose packages.json lists tap formulas $argv'
    set -l d (mktemp -d)
    set -ga _tmp $d
    mkdir $d/.chezmoidata
    jq -n '{brew_tap_packages: $ARGS.positional}' --args $argv > $d/.chezmoidata/packages.json
    echo $d
end

function _trust --description 'render the config template for source $argv[1] (rest: chezmoi flags), read brew_tap_trust back as chezmoi would'
    set -l cfg (mktemp --suffix .toml)
    set -ga _tmp $cfg
    chezmoi --config $_bare_cfg --source $argv[1] execute-template --init $argv[2..-1] < $_cfg_tmpl > $cfg; or return 1
    chezmoi --config $cfg execute-template '{{ get . "brew_tap_trust" | default dict | toJson }}'
end

@echo "config template: trust per tap"

set -l s (_src oven-sh/bun/bun)
@test "an answer is stored under the tap" \
    (_trust $s --promptBool 'Trust Homebrew tap oven-sh/bun=true') = '{"oven-sh/bun":true}'

set -l s (_src oven-sh/bun/bun)
@test "a stored answer is kept without prompting" \
    (_trust $s --override-data '{"brew_tap_trust":{"oven-sh/bun":true}}') = '{"oven-sh/bun":true}'

set -l s (_src a/t/x a/t/y)
@test "two formulas from one tap give one key" \
    (_trust $s --promptBool 'Trust Homebrew tap a/t=true') = '{"a/t":true}'

set -l s (_src oven-sh/bun/bun)
@test "a tap no longer in data is dropped" \
    (_trust $s --override-data '{"brew_tap_trust":{"old/tap":true,"oven-sh/bun":true}}') = '{"oven-sh/bun":true}'

set -l s (_src)
@test "no tap formulas renders a valid config" \
    (_trust $s) = '{}'

@echo "chezmoi.test.toml answers every tap (the Docker build has no TTY)"

set -l answered (chezmoi --config $_repo_root/chezmoi.test.toml execute-template '{{ range $k, $v := get . "brew_tap_trust" | default dict }}{{ $k }}{{ "\n" }}{{ end }}')
for t in (jq -r '.brew_tap_packages[] | sub("/[^/]*$"; "")' $_repo_root/home/.chezmoidata/packages.json | sort -u)
    @test "chezmoi.test.toml answers tap $t" \
        (contains -- $t $answered; and echo yes; or echo no) = yes
end

trash $_tmp
