-- Pull in the wezterm API
local wezterm = require("wezterm")

function get_appearance()
  if wezterm.gui then
    return wezterm.gui.get_appearance()
  end
  return 'Dark'
end

function scheme_for_appearance(appearance)
  if appearance:find 'Dark' then
    return "Dracula (Official)"
  else
    return "Atom One Light"
  end
end

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
	config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = scheme_for_appearance(get_appearance())
config.use_fancy_tab_bar = false
config.window_decorations = "RESIZE"

-- Fonts
config.font = wezterm.font("Fira Mono")
config.font_size = 18

-- Spawn a fish shell in login mode
config.default_prog = { '/usr/bin/fish', '-l' }

return config
