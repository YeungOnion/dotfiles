function __append_pipe_fzf
    switch (commandline --is-valid)
        case 2
            echo -e "\nIncomplete command, cannot page its output"
        case 1
            echo -e "\nErroneous command, cannot page its output"
        case '*'
            set -f cmd2fzf ''
            commandline | read -at cmd2fzf

            set -f op_view 'bat {}'
            set -f op_edit 'hx {}'
            set -f op_cp 'echo {} | fish_clipboard_copy'

            _fzf_wrapper --multi --ansi --height=60% \
                --bind "start:reload:$cmd2fzf" \
                --bind "f1:become($op_view),ctrl-e:become($op_edit),ctrl-y:execute-silent($op_cp)+abort"
    end

    commandline --function repaint
end
