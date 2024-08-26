function diary --description 'adds entry to day of week named files diary'
    # header to use/seek
    set header (date '+# %Y-%m-%d')

    # identify diary directory, as git project or ~
    if test (git rev-parse --show-toplevel 2>/dev/null)
        set -l top_level (git rev-parse --show-toplevel)
        set -f diary_dir $top_level/diary/
        mkdir -p $diary_dir
    else
        set -f diary_dir $HOME/.local/share/diary/
    end

    # find if header already used
    if set pieces (rg --vimgrep $header $diary_dir | string split ':')
        set pieces[2] (__math_succ $pieces[2])
        # target file one line after match
        set -f target (string join ':' $pieces[1..2])
    else
        # else, prepend it
        set tmp_fname /tmp/diary
        set fname "$diary_dir/$(date '+%a').md" && touch $fname
        echo -es "$header\n" | cat - $fname > $tmp_fname &&
            mv -f $tmp_fname $fname
        # and open on second line
        set -f target "$fname:2"
    end
    hx $target

end
