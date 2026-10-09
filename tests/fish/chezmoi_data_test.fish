#!/usr/bin/env fish
# chezmoi data lives in JSON under home/.chezmoidata/ so tasks can edit it with jq
# Run: fishtape tests/fish/chezmoi_data_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _data $_repo_root/home/.chezmoidata

@echo "data files"

@test "no TOML data file" \
    (test -e $_repo_root/home/.chezmoidata.toml && echo yes || echo no) = no

@test "packages.json is valid JSON" \
    (jq -e . $_data/packages.json >/dev/null 2>&1 && echo yes || echo no) = yes

@test "fish.json is valid JSON" \
    (jq -e . $_data/fish.json >/dev/null 2>&1 && echo yes || echo no) = yes

@echo "data reaches templates"

for key in brew_packages brew_packages_linux brew_packages_darwin cargo_plugins cargo_binaries uv_packages fish_plugins
    @test "$key renders as a list" \
        (chezmoi execute-template "{{ kindOf .$key }}" 2>&1) = slice
end

@test "fish_universal renders as a map" \
    (chezmoi execute-template '{{ kindOf .fish_universal }}' 2>&1) = map

@echo "fish_plugins entries have fisher's owner/repo shape"

# fisher parses fish_plugins with ^[^\s]+$ and compares lowercased names: case is
# harmless, a trailing slash or whitespace makes a different (missing) plugin
for p in (jq -r '.fish_plugins[]' $_data/fish.json 2>/dev/null)
    @test "$p is owner/repo" \
        (string match -qr '^[^/\s]+/[^/\s]+(@\S+)?$' -- $p && echo yes || echo no) = yes
end

@echo "live data satisfies the schema"

for f in $_data/*.json
    @test (path basename $f)" satisfies the schema" \
        (jq -L $_repo_root/scripts 'include "data-schema"; violations | length' $f) = 0
end
