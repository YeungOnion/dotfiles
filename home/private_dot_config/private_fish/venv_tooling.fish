set -gx CONDA_EXE "$HOME/mambaforge/bin/conda"
set _CONDA_ROOT "$HOME/mambaforge"
set _CONDA_EXE "$HOME/mambaforge/bin/conda"
set -gx CONDA_PYTHON_EXE "$HOME/mambaforge/bin/python"
# Copyright (C) 2012 Anaconda, Inc
# SPDX-License-Identifier: BSD-3-Clause
#
# INSTALL
#
#     Run 'conda init fish' and restart your shell.
#

## conda mgmt vars
if not set -q CONDA_SHLVL
    set -gx CONDA_SHLVL 0
    set -g _CONDA_ROOT (dirname (dirname $CONDA_EXE))
    set -gx PATH $_CONDA_ROOT/condabin $PATH
end

# ====================
# === PROMPT SETUP ===
# ====================

## === PROMPT DEFS ===
function __conda_add_prompt
    if set -q CONDA_PROMPT_MODIFIER
        set_color -o green
        echo -n $CONDA_PROMPT_MODIFIER
        set_color normal
    end
end

function __pixi_add_prompt
    if set -q PIXI_PROMPT
        set_color -o green
        echo -n $PIXI_PROMPT
        set_color normal
    end
end

## === FISH PROMPT CHANGES ===
for prompt_type in fish_prompt fish_right_prompt
    set -l new_prompt_name __"$prompt_type"_orig
    if functions -q $prompt_type
        if not functions -q $new_prompt_name
            functions --copy $prompt_type $new_prompt_name
        end
        functions --erase $prompt_type
    else
        # if you didn't have one before make it emit nothing
        function $new_prompt_name
        end
    end
end

function return_last_status
    return $argv
end

function fish_prompt
    set -l last_status $status
    if set -q CONDA_LEFT_PROMPT
        __conda_add_prompt
        if functions -q __pixi_add_prompt
            __pixi_add_prompt
        end
    end
    return_last_status $last_status
    __fish_prompt_orig
end

    
function fish_right_prompt
    if not set -q CONDA_LEFT_PROMPT
        __conda_add_prompt
        if functions -q __pixi_add_prompt
            __pixi_add_prompt
        end
    end
    __fish_right_prompt_orig
end


function conda --inherit-variable CONDA_EXE
    if [ (count $argv) -lt 1 ]
        $CONDA_EXE
    else
        set -l cmd $argv[1] && set -e argv[1]
        switch $cmd
            case activate deactivate
                eval ($CONDA_EXE shell.fish $cmd $argv)
            case install update upgrade remove uninstall
                $CONDA_EXE $cmd $argv
                and eval ($CONDA_EXE shell.fish reactivate)
            case '*'
                $CONDA_EXE $cmd $argv
        end
    end
end

## mamba 
if test -f $HOME/mambaforge/etc/fish/conf.d/mamba.fish
    source $HOME/mambaforge/etc/fish/conf.d/mamba.fish
end


# Autocompletions below


# Faster but less tested (?)
function __fish_conda_commands
    string replace -r '.*_([a-z]+)\.py$' '$1' $_CONDA_ROOT/lib/python*/site-packages/conda/cli/main_*.py
    for f in $_CONDA_ROOT/bin/conda-*
        if test -x "$f" -a ! -d "$f"
            string replace -r '^.*/conda-' '' "$f"
        end
    end
    echo activate
    echo deactivate
end

function __fish_conda_env_commands
    string replace -r '.*_([a-z]+)\.py$' '$1' $_CONDA_ROOT/lib/python*/site-packages/conda_env/cli/main_*.py
end

function __fish_conda_envs
    conda config --json --show envs_dirs | python -c "import json, os, sys; from os.path import isdir, join; print('\n'.join(d for ed in json.load(sys.stdin)['envs_dirs'] if isdir(ed) for d in os.listdir(ed) if isdir(join(ed, d))))"
end

function __fish_conda_packages
    conda list | awk 'NR > 3 {print $1}'
end

function __fish_conda_needs_command
    set cmd (commandline -opc)
    if [ (count $cmd) -eq 1 -a $cmd[1] = conda ]
        return 0
    end
    return 1
end

function __fish_conda_using_command
    set cmd (commandline -opc)
    if [ (count $cmd) -gt 1 ]
        if [ $argv[1] = $cmd[2] ]
            return 0
        end
    end
    return 1
end

# Conda commands
complete -f -c conda -n __fish_conda_needs_command -a '(__fish_conda_commands)'
complete -f -c conda -n '__fish_conda_using_command env' -a '(__fish_conda_env_commands)'

# Commands that need environment as parameter
complete -f -c conda -n '__fish_conda_using_command activate' -a '(__fish_conda_envs)'

# Commands that need package as parameter
complete -f -c conda -n '__fish_conda_using_command remove' -a '(__fish_conda_packages)'
complete -f -c conda -n '__fish_conda_using_command uninstall' -a '(__fish_conda_packages)'
complete -f -c conda -n '__fish_conda_using_command upgrade' -a '(__fish_conda_packages)'
complete -f -c conda -n '__fish_conda_using_command update' -a '(__fish_conda_packages)'
