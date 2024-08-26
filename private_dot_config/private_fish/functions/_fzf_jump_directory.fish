function _fzf_jump_directory --description 'fzf wrapper for picking with z'

  if not type -q z
    set_color red
      echo "_fzf_jump_directory: z not found." >&2
    set_color normal
    return 1
  end

  set current_token (commandline --current-token)

  set command_z (
    z -l | sort -rn | cut -c 12- | _fzf_wrapper --query=$current_token $fzf_jump_directory_opts --preview='_fzf_preview_file {}'
  )

  if test $status -eq 0
    cd $command_z
  end

  commandline --function repaint

end
