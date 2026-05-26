abbr --add jk --position command prevd
abbr --add kj --position command nextd
abbr --add grep --position command rg -uu # like grep -R
abbr --add find --position command fd -IH
abbr --add rm --position command trash # try to use trash pls
abbr --add g --position command git
abbr --add gco --position command git checkout
abbr --add sg --position command ast-grep
abbr --add tree --position command tree --gitignore
abbr --add glow --position command glow --pager
abbr --add ardo --position command arduino-cli

alias du 'du -h'
alias mkdir 'mkdir -p'
alias tmux 'TERM=xterm-256color command tmux'
alias glow 'glow --width 120'

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
abbr --add sl --position command ls

# utils
abbr .4dir --set-cursor="<+++>" "$(string join \n -- 'for dir in */' 'pushd $dir' '<+++>' 'popd' 'end')"

# tar is a monster
abbr --add targzip --position command 'tar --create --gzip --verbose --file'
abbr --add targunzip --position command 'tar --extract --verbose --file'
abbr --add tarshow --position command 'tar --list --file'
