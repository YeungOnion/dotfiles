function __append_pipe_fzf
    switch (commandline --is-valid)
    case 2
        echo -e "\nIncomplete command, cannot page its output"
    case 1
        echo -e "\nErroneous command, cannot page its output"
    case '*'
        set -l cmd2fzf ''
        commandline | read -at cmd2fzf

        set -l fzf_selections (echo ($cmd2fzf | _fzf_wrapper --multi --ansi --height=60%))
        if test -n $fzf_selections
            echo $fzf_selections
        else
            echo 'exited with error, fzf_selections not set'
        end
    end

    commandline --function repaint
end
