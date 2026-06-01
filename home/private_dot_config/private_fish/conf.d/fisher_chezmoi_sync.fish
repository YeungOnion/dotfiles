function _fisher_sync_chezmoiignore
    set -l src (chezmoi source-path 2>/dev/null)
    test -n "$src" || return

    set -l ignore $src/.chezmoiignore
    set -l fish_dirs \
        ~/.config/fish/functions \
        ~/.config/fish/conf.d \
        ~/.config/fish/completions

    set -l fisher_files (chezmoi unmanaged $fish_dirs 2>/dev/null)

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
