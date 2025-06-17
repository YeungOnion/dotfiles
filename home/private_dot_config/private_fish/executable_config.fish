# $XDG_CONFIG/fish/config.fish

# for stuff in path that needs a path or targets
set -gx --path RUSTUP_HOME $HOME/.rustup
set -gx --path CARGO_HOME $HOME/.cargo
set -gx --path GOPATH $HOME/.go
if command -q go
    set -gx GOBIN (go env GOPATH)/bin
end
set -gx CC cc

if status is-interactive

    # fzf related
    set fd_cmd (command -s fd || command -s fdfind)
    set -g FZF_DEFAULT_COMMAND $fd_cmd
    set -g FZF_DEFAULT_OPTS --ansi

    # pager related
    if command -q bat batcat
        # create soft link if not exist, overwrite otherwise
        ln --symbolic --force (command -s bat batcat)[-1] ~/.local/bin/bat
        set -g PAGER bat
        set -g MANPAGER "sh -c 'sed -u -e \"s/\\x1B\[[0-9;]*m//g; s/.\\x08//g\" | bat -p -lman'"
    else
        echo "cannot find `bat' pager, choosing `cat' instead" >&2
        set -g PAGER cat
    end

    # for tools I use directly and fisher funcs
    set -g sponge_purge_only_on_exit true
    set -g fzf_fd_opts --hidden --exclude="**/target/*" \
        --exclude="**/build/*" --exclude="**/{.mypy,.ruff}_cache/*" \
        --exclude="**/.git/{objects,refs,logs}/*" \
        --exclude="**/.pixi/env/*"
    set -g EDITOR hx

    if test -f ~/.asdf/asdf.fish
        source ~/.asdf/asdf.fish
        echo "`asdf' not found, not loading it" &>2
    end

    fish_add_path $RUSTUP_HOME/bin $CARGO_HOME/bin $GOPATH/bin $HOME/.local/bin $HOME/.pixi/bin
    source $__fish_config_dir/aliases.fish
end
