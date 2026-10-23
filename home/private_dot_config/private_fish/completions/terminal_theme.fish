complete -c terminal_theme -f
complete -c terminal_theme -n 'test (count (commandline -opc)) -eq 1' -a light -d 'set light'
complete -c terminal_theme -n 'test (count (commandline -opc)) -eq 1' -a dark -d 'set dark'
complete -c terminal_theme -n 'test (count (commandline -opc)) -eq 1' -a toggle -d 'switch light/dark'
