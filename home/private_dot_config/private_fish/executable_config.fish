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
    fzf_configure_bindings --directory='super-p'

    # pager related
    if command -s bat batcat
        # create soft link if not exist, overwrite otherwise
        ln --symbolic --force (command -s bat batcat)[-1] ~/.local/bin/bat
        set -gx PAGER bat -p
        set -g MANPAGER batman
    else
        echo "cannot find `bat' pager, choosing `cat' instead" >&2
        set -gx PAGER cat
    end

    # for tools I use directly and fisher funcs
    set -g sponge_purge_only_on_exit true
    set -gx fzf_fd_opts --hidden --exclude="**/target/*" \
        --exclude="**/build/*" --exclude="**/{.mypy,.ruff}_cache/*" \
        --exclude="**/.git/{objects,refs,logs}/*" \
        --exclude="**/.pixi/env/*"
    set -gx fzf_git_log_opts --preview-window "down,70%"
    set -gx EDITOR hx

    if test -f ~/.asdf/asdf.fish
        source ~/.asdf/asdf.fish
    else
        echo "`asdf' not found, not loading it" >&2
    end

    fish_add_path $RUSTUP_HOME/bin $CARGO_HOME/bin $GOPATH/bin $HOME/.local/bin $HOME/.pixi/bin
    source $__fish_config_dir/aliases.fish

    # projects
    direnv hook fish | source
    mise activate fish | source
end

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/onion/packages/google-cloud-sdk/path.fish.inc' ]
    . '/Users/onion/packages/google-cloud-sdk/path.fish.inc'
end
