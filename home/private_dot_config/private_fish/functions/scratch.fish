function scratch --description 'open into subdir in $HOME/sandbox/(today)/'
    set -f target "$HOME" sandbox "$(date +%y%m%d)" $argv[-1]
    if test (count $argv) -ne 1
        echo "Expected 1 argument, got $(count argv)" >/dev/stderr
    end
    set -f target_path (string join "/" $target)
    mkdir --parents $target_path
    cd $target_path
end
