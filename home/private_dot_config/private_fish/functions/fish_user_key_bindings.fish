function fish_user_key_bindings --description 'use this instead of caling bind in config'
    bind --user ctrl-z _fzf_jump_directory
    bind --user alt-p __append_pipe_fzf
    # setting the below so terminal emulator can use it
    bind -e f1
    fzf_configure_bindings --directory='ctrl-alt-f'
end
