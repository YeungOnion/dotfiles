#!/usr/bin/env fish
# chezmoi otherwise creates files with the applying shell's umask: under 0002 an apply
# made ~/.claude hooks group-writable. The config template pins it to 022.
# Renders into a temp dir and applies to a temp destination; the host is never touched.
# Run: fishtape tests/fish/umask_test.fish

set -g _repo_root (path resolve (status dirname)/../..)
set -g _src $_repo_root/home
set -g _tmp (mktemp -d)

# chezmoi.test.toml answers every prompt*Once, so the render needs no TTY
chezmoi --config $_repo_root/chezmoi.test.toml --source $_src execute-template --init \
    < $_src/.chezmoi.toml.tmpl > $_tmp/chezmoi.toml
printf '[data]\n  java_home = ""\n' > $_tmp/bare.toml

mkdir -p $_tmp/src
echo x > $_tmp/src/dot_file

function _applied_mode --description 'apply the tiny source under umask 0002 with config $argv[1], print the file mode'
    set -l dest (mktemp -d -p $_tmp)
    # a fresh state path (not a mktemp'd empty file, which chezmoi rejects for the real one)
    fish --no-config -c 'umask 0002; chezmoi --config $argv[1] --source $argv[2] --destination $argv[3] --persistent-state $argv[3].boltdb apply --no-tty' \
        $argv[1] $_tmp/src $dest </dev/null; or return 1
    stat -c %a $dest/.file
end

@echo "config template pins umask"

@test "rendered config sets umask 022" \
    (chezmoi --config $_tmp/chezmoi.toml dump-config --format json | jq .umask) = 18

@test "without it, an apply under umask 0002 makes the file group-writable" \
    (_applied_mode $_tmp/bare.toml) = 664

@test "with it, an apply under umask 0002 writes 644" \
    (_applied_mode $_tmp/chezmoi.toml) = 644

trash $_tmp
