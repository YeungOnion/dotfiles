function __git_rg --description 'searches using rg, but also shows functino header with git grep'
    rg -l $argv | xargs git grep --show-function --break --heading --line-number $argv
end
