# ~/.config/fish/config.fish

# for stuff in path that needs a path or targets
set -gx --path RUSTUP_HOME $HOME/.rustup
set -gx --path CARGO_HOME $HOME/.cargo
set -gx --path GOPATH $HOME/.go
set -gx CC cc

if status is-interactive

    # fzf related
    set -x fd_cmd (which fd || which fdfind)
    set -gx FZF_DEFAULT_COMMAND $fd_cmd
    set -gx FZF_DEFAULT_OPTS --ansi

    # pager related
    if command -q bat
        set -x bat_cmd bat
    else if test which bat -o which batcat
        set -x bat_cmd (which bat || which batcat)
    else
        echo 'cannot find bat pager, setting $bat_cmd=''bat'''
        set -x bat_cmd bat
    end
    set -gx MANPAGER "fish -c 'col -bx | $bat_cmd -plman'"
    set -gx PAGER $bat_cmd

    # for tools I use directly and fisher funcs
    set -gx sponge_purge_only_on_exit true
    set -gx fzf_fd_opts --hidden --exclude="**/target/*" \
        --exclude="**/build/*" --exclude="**/{.mypy,.ruff}_cache/*" \
        --exclude="**/.git/{objects,refs,logs}/*" \
        --exclude="**/.pixi/env/*"
    set -gx EDITOR hx

    if test -f ~/.asdf/asdf.fish
        source ~/.asdf/asdf.fish
    else
        echo '''asdf'' not found, not loading it'
    end

    fish_add_path $RUSTUP_HOME/bin $CARGO_HOME/bin $GOPATH/bin $HOME/.local/bin $HOME/.pixi/bin
    source $__fish_config_dir/aliases.fish
end

if test -d $__fish_config_dir/venv_tooling.fish
    source $__fish_config_dir/venv_tooling.fish
end

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /home/orion/mambaforge/bin/conda
    eval /home/orion/mambaforge/bin/conda "shell.fish" hook $argv | source
end

if test -f "/home/orion/mambaforge/etc/fish/conf.d/mamba.fish"
    source "/home/orion/mambaforge/etc/fish/conf.d/mamba.fish"
end
# <<< conda initialize <<<
