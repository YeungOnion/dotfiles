#!/usr/bin/env fish
# Tests for scripts/data-edit — runs only against temp JSON files
# Run: fishtape tests/fish/data_edit_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _edit $_repo_root/scripts/data-edit

set -g _fixtures
function _fixture
    set -l f (mktemp --suffix .json)
    set -ga _fixtures $f
    echo '{"pkgs": ["a", "b"], "vars": {"X": "1"}}' | jq . > $f
    echo $f
end

@echo "list-add"

set -l f (_fixture)
@test "list-add appends a new value" \
    ($_edit $f list-add pkgs c; and jq -c .pkgs $f) = '["a","b","c"]'

set -l f (_fixture)
set -l before (stat -c %Y.%s $f)
@test "list-add of a present value exits 0" \
    ($_edit $f list-add pkgs a 2>/dev/null; echo $status) = 0
@test "list-add of a present value leaves the file untouched" \
    (stat -c %Y.%s $f) = $before

set -l f (_fixture)
@test "list-add on a missing key fails" \
    ($_edit $f list-add nope c 2>/dev/null; echo $status) = 1

@echo "list-remove"

set -l f (_fixture)
@test "list-remove drops the value" \
    ($_edit $f list-remove pkgs a; and jq -c .pkgs $f) = '["b"]'

set -l f (_fixture)
@test "list-remove of an absent value fails" \
    ($_edit $f list-remove pkgs zzz 2>/dev/null; echo $status) = 1
@test "failed list-remove leaves the file valid and unchanged" \
    (jq -c .pkgs $f) = '["a","b"]'

@echo "map-set / map-unset"

set -l f (_fixture)
@test "map-set adds a name" \
    ($_edit $f map-set vars Y 2; and jq -c .vars $f) = '{"X":"1","Y":"2"}'

set -l f (_fixture)
@test "map-set overwrites a name" \
    ($_edit $f map-set vars X 9; and jq -r .vars.X $f) = 9

set -l f (_fixture)
@test "map-unset removes a name" \
    ($_edit $f map-unset vars X; and jq -c .vars $f) = '{}'

set -l f (_fixture)
@test "map-unset of an absent name fails" \
    ($_edit $f map-unset vars NOPE 2>/dev/null; echo $status) = 1

@echo "errors"

set -l f (_fixture)
@test "unknown operation fails" \
    ($_edit $f frobnicate pkgs a 2>/dev/null; echo $status) = 1

@test "too few arguments is a usage error" \
    ($_edit 2>/dev/null; echo $status) = 2

@test "stdout stays empty on success" \
    (count ($_edit (_fixture) list-add pkgs z)) = 0

@echo "result validation"

function _fixture_data
    set -l f (mktemp --suffix .json)
    set -ga _fixtures $f
    echo '{"fish_plugins": ["patrickf1/fzf.fish"], "brew_packages": ["bat"], "fish_universal": {"EDITOR": "hx"}}' | jq . > $f
    chmod 644 $f
    echo $f
end

set -l f (_fixture_data)
set -l before (sha256sum < $f)
@test "case-only duplicate plugin is rejected" \
    ($_edit $f list-add fish_plugins PatrickF1/fzf.fish 2>/dev/null; echo $status) = 1
@test "rejected edit leaves the file byte-identical" \
    (sha256sum < $f) = $before

set -l f (_fixture_data)
@test "plugin without owner/repo shape is rejected" \
    ($_edit $f list-add fish_plugins fzf.fish 2>/dev/null; echo $status) = 1

set -l f (_fixture_data)
@test "package name with whitespace is rejected" \
    ($_edit $f list-add brew_packages 'two words' 2>/dev/null; echo $status) = 1

set -l f (_fixture_data)
@test "package name with ; is rejected" \
    ($_edit $f list-add brew_packages 'x;rm' 2>/dev/null; echo $status) = 1

set -l f (_fixture_data)
@test "invalid variable name is rejected" \
    ($_edit $f map-set fish_universal 1BAD x 2>/dev/null; echo $status) = 1

set -l f (_fixture_data)
@test "rejection names the violation" \
    (string match -q '*fish_plugins*' ($_edit $f list-add fish_plugins fzf.fish 2>&1); and echo yes; or echo no) = yes

set -l f (_fixture_data)
@test "valid edit keeps the file mode" \
    ($_edit $f list-add brew_packages fd; and stat -c %a $f) = 644

set -l bad (mktemp --suffix .json)
set -ga _fixtures $bad
echo '{not json' > $bad
@test "invalid JSON input is reported as invalid JSON" \
    (string match -q '*invalid JSON*' ($_edit $bad list-add pkgs a 2>&1); and echo yes; or echo no) = yes

# only the files this test created
trash $_fixtures
