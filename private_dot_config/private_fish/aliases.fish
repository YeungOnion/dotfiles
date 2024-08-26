abbr --add jk --position command prevd
abbr --add kj --position command nextd
abbr --add cat --position command "$bat_cmd -p --color never"
abbr --add grep --position command rg -uu # like grep -R
abbr --add rm --position command trash # try to use trash pls
abbr --add g --position command git
abbr --add sg --position command ast-grep

alias bat "$bat_cmd --diff-context 5"
alias du 'du -h'
alias mkdir 'mkdir -p'

if command -q git-branchless
    alias git 'git-branchless wrap -- '
end

function today --wraps=date
    date +%y%m%d
end

function mkcd --wraps=mkdir
    mkdir -p $argv[-1]
    cd $argv[-1]
end

# Prevents accidentally clobbering files.
alias rm 'rm -i'
alias cp 'cp -i'
alias mv 'mv -i'

# typos
alias sl ls

# tar is a monster
abbr --add targzip --position command 'tar --create --gzip --verbose --file'
abbr --add targunzip --position command 'tar --extract --verbose --file'
abbr --add tarshow --position command 'tar --list --file'
