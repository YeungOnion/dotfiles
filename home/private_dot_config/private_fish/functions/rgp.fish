function rgp
    rg --line-number --no-heading --color=always --smart-case $argv | fzf -d ':' -n 2.. --ansi --no-sort --preview-window 'down:40%:+{2}' \
        --preview 'bat --style=numbers --color=always --highlight-line {2} {1}'
end
