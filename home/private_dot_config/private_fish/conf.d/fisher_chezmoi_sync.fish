function _fisher_sync_chezmoiignore
    set -l src (chezmoi source-path 2>/dev/null)
    test -n "$src" || return

    set -l ignore $src/.chezmoiignore
    set -l fish_dirs \
        ~/.config/fish/functions \
        ~/.config/fish/conf.d \
        ~/.config/fish/completions

    # chezmoi managed lists user-owned files; everything else in the dirs is fisher's
    set -l managed (chezmoi managed $fish_dirs 2>/dev/null)
    set -l fisher_files
    for dir in $fish_dirs
        test -d $dir || continue
        for f in $dir/*.fish
            test -f $f || continue
            set -l rel (string replace -- "$HOME/" "" $f)
            contains -- $rel $managed
            or set -a fisher_files $rel
        end
    end

    set -l preserved
    if test -f $ignore
        set preserved (awk '/^# fisher:begin/{skip=1} /^# fisher:end/{skip=0; next} !skip{print}' $ignore)
    end

    begin
        printf '%s\n' $preserved
        printf '# fisher:begin\n'
        printf '%s\n' $fisher_files
        printf '# fisher:end\n'
    end > $ignore
end

function _fisher_postexec_sync --on-event fish_postexec
    string match -qr '^fisher (install|remove|update)' -- $argv[1]
    or return
    command -q chezmoi
    or return
    _fisher_sync_chezmoiignore
end
