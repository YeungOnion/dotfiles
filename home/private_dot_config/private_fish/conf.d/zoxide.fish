# zoxide replaces jethrokuan/z and keeps the `z` command. History lives per machine
# in ~/.local/share/zoxide and is only ever written by zoxide.
status is-interactive; and command -q zoxide; and zoxide init fish --cmd z | source
