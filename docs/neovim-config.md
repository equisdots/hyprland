# Neovim Configuration

Neovim is **not installed from any external repo**. Use your own Neovim config
(clone/keep it in `~/.config/nvim`); the installer only themes it through
[`equisdots/theme-sync`](https://github.com/equisdots/theme-sync).

## Theming

The theme engine in `lua/themes/` applies highlight groups from `palettes.lua`.
`theme-sync` regenerates `lua/themes/palettes.lua` and `lua/config/theme.lua`
from `dock/palettes` so Neovim follows the same palette as the bar, kitty,
starship and VS Code. Files without the theme-sync markers are never touched.

## Post-install

1. Open `nvim` → Lazy installs plugins (`:Lazy`).
2. `:Mason` to install LSP servers.
3. Refer to your nvim config README / cheatsheet for usage.
