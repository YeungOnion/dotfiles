#!/usr/bin/env bash

# ==============================================================================
# 1. READ STATE
# ==============================================================================
get_windows_theme() {
    local reg_key="HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    local reg_query
    reg_query=$(reg.exe query "$reg_key" /v AppsUseLightTheme 2>/dev/null)

    if echo "$reg_query" | grep -q "0x1"; then
        echo "light"
    else
        echo "dark"
    fi
}

# ==============================================================================
# 2. SET STATE & DATA MAPS
# ==============================================================================
get_claude_payload() {
    local mode="$1"
    echo "{\"name\":\"Custom Auto\",\"base\":\"${mode}\"}"
}

get_tmux_palette_path() {
    local mode="$1"
    # Fallback syntax: If XDG_CONFIG_HOME is empty, use $HOME/.config
    local config_root="${XDG_CONFIG_HOME:-$HOME/.config}"
    echo "${config_root}/tmux/conf.d/palette_${mode}.conf"
}

# ==============================================================================
# 3. CAUSE EFFECTS
# ==============================================================================
apply_theme_effects() {
    local mode="$1"
    # Claude Code hardcodes its lookup path to $HOME/.claude regardless of XDG environment
    local claude_file="$HOME/.claude/themes/custom.json"
    
    # Absolute path safety boundaries
    mkdir -p "$(dirname "$claude_file")"
    local payload
    payload=$(get_claude_payload "$mode")
    
    if [ ! -f "$claude_file" ] || [ "$(cat "$claude_file")" != "$payload" ]; then
        echo "$payload" > "$claude_file"
    fi

    local tmux_palette
    tmux_palette=$(get_tmux_palette_path "$mode")
    if [ -f "$tmux_palette" ]; then
        tmux source-file "$tmux_palette"
    fi
}

main() {
    local current_mode
    current_mode=$(get_windows_theme)
    apply_theme_effects "$current_mode"
}

main
