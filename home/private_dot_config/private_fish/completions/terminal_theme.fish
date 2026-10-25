complete -c terminal_theme -f
complete -c terminal_theme -n 'test (count (commandline -opc)) -eq 1' -a light -d 'target light'
complete -c terminal_theme -n 'test (count (commandline -opc)) -eq 1' -a dark -d 'target dark'
complete -c terminal_theme -n 'test (count (commandline -opc)) -eq 1' -a toggle -d 'switch the target'
complete -c terminal_theme -n 'test (count (commandline -opc)) -eq 1' -a apply -d 'reapply the target'
complete -c terminal_theme -n 'test (count (commandline -opc)) -eq 1' -a system -d 'target the Windows theme'
