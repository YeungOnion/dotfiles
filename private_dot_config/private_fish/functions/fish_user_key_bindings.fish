function fish_user_key_bindings --description 'use this instead of caling bind in config'
    bind --user \cZ _fzf_jump_directory
    bind --user \e\/ __append_pipe_fzf
    # setting the below so terminal emulator can use it
    bind -e -k f1
end
