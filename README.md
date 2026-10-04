<h1 align="center">equisdots · hyprland</h1>

<p align="center">
  <img src="https://img.shields.io/github/license/equisdots/hyprland?style=flat-square&color=blue" alt="License">
  <img src="https://img.shields.io/github/last-commit/equisdots/hyprland?style=flat-square&color=blueviolet" alt="Last Commit">
  <img src="https://img.shields.io/github/repo-size/equisdots/hyprland?style=flat-square&color=success" alt="Repo Size">
  <img src="https://img.shields.io/badge/Hyprland-v0.55+-8A2BE2?style=flat-square" alt="Hyprland">
  <img src="https://img.shields.io/badge/Arch_Linux-supported-1793D1?style=flat-square&logo=arch-linux" alt="Arch">
  <img src="https://img.shields.io/badge/Palettes-12-FF69B4?style=flat-square" alt="Palettes">
</p>

<p align="center">
  <em>
  Hyprland compositor configuration for the equisdots desktop: modular Lua
  config, palette-driven theming and system scripts.
  </em>
</p>

<h2 align="center">Content</h2>

<p align="center">
  <a href="#previews">Previews</a> &middot;
  <a href="#quick-install">Quick Install</a> &middot;
  <a href="#features">Features</a> &middot;
  <a href="#customization">Customization</a> &middot;
  <a href="#quick-reference">Quick Reference</a> &middot;
  <a href="#structure">Structure</a> &middot;
  <a href="#documentation">Documentation</a> &middot;
  <a href="#related-repos">Related Repos</a>
</p>

---

## Previews

<details>
<summary>previews</summary>

<p>Captures served from the <a href="https://equisdots.github.io/web/previews/">website previews page</a> (hotlinked; no images are stored in this repository).</p>

<h3>The desktop</h3>

<p align="center">
  <a href="https://equisdots.github.io/web/previews/shots/desktop-doctor.webp"><img src="https://equisdots.github.io/web/previews/shots/desktop-doctor-1280.webp" alt="The full desktop" width="100%"></a>
  <br>
  <sub><strong>The full desktop</strong> -- equisdots doctor, the timex TUI and btop over an interactive scene.</sub>
</p>

<p align="center">
  <a href="https://equisdots.github.io/web/previews/shots/desktop-tiling.webp"><img src="https://equisdots.github.io/web/previews/shots/desktop-tiling-1280.webp" alt="Tiling and panels" width="100%"></a>
  <br>
  <sub><strong>Tiling and panels</strong> -- Hyprland tiling with btop, the widgets panel and the settings editor at once.</sub>
</p>

<p align="center">
  <a href="https://equisdots.github.io/web/previews/shots/desktop-scenes.webp"><img src="https://equisdots.github.io/web/previews/shots/desktop-scenes-1280.webp" alt="Scenes and monitors" width="100%"></a>
  <br>
  <sub><strong>Scenes and monitors</strong> -- a scene wallpaper reacting to the palette, with the system monitor and terminal UI on top.</sub>
</p>

<h3>Shell and settings</h3>

<p align="center">
  <a href="https://equisdots.github.io/web/previews/shots/bar.webp"><img src="https://equisdots.github.io/web/previews/shots/bar-1280.webp" alt="Bar islands" width="100%"></a>
  <br>
  <sub><strong>Bar islands</strong> -- workspaces, clock and status islands: palette-tinted, blur-aware and position-independent.</sub>
</p>

<p align="center">
  <a href="https://equisdots.github.io/web/previews/shots/settings-bar-engine.webp"><img src="https://equisdots.github.io/web/previews/shots/settings-bar-engine-1280.webp" alt="Bar engine" width="100%"></a>
  <br>
  <sub><strong>Bar engine</strong> -- pick an engine (Bar, ClassicBar) and preview its modules and zones live.</sub>
</p>

<p align="center">
  <a href="https://equisdots.github.io/web/previews/shots/settings-bar-position.webp"><img src="https://equisdots.github.io/web/previews/shots/settings-bar-position-1280.webp" alt="Bar position" width="100%"></a>
  <br>
  <sub><strong>Bar position</strong> -- move the bar to any edge; the preview reflects position and zones.</sub>
</p>

<p align="center">
  <a href="https://equisdots.github.io/web/previews/shots/settings-timex.webp"><img src="https://equisdots.github.io/web/previews/shots/settings-timex-640.webp" alt="Timex" width="100%"></a>
  <br>
  <sub><strong>Timex</strong> -- weather provider, city, forecast layout and calendar popup options.</sub>
</p>

<p align="center">
  <a href="https://equisdots.github.io/web/previews/shots/settings-monitors.webp"><img src="https://equisdots.github.io/web/previews/shots/settings-monitors-640.webp" alt="Monitors" width="100%"></a>
  <br>
  <sub><strong>Monitors</strong> -- resolution, refresh rate, VRR, bit depth, HDR and mirroring per output.</sub>
</p>

<p align="center">
  <a href="https://equisdots.github.io/web/previews/shots/settings-glass.webp"><img src="https://equisdots.github.io/web/previews/shots/settings-glass-1280.webp" alt="Glass and blur" width="100%"></a>
  <br>
  <sub><strong>Glass and blur</strong> -- translucency for popups, menus and the bar; blur comes from a Hyprland layer rule.</sub>
</p>

<p align="center">
  <a href="https://equisdots.github.io/web/previews/shots/widgets-panel.webp"><img src="https://equisdots.github.io/web/previews/shots/widgets-panel-640.webp" alt="Widgets panel" width="100%"></a>
  <br>
  <sub><strong>Widgets panel</strong> -- the floating hub: palettes, settings and desktop widgets one tap away.</sub>
</p>

<p align="center">
  <a href="https://equisdots.github.io/web/previews/shots/app-launcher.webp"><img src="https://equisdots.github.io/web/previews/shots/app-launcher.webp" alt="App launcher" width="240"></a>
  <br>
  <sub><strong>App launcher</strong> -- fuzzy search over installed applications with instant launch.</sub>
</p>

</details>

<details>
<summary>gifs previews</summary>

<p>Clips served from the <a href="https://equisdots.github.io/web/previews/#clips">website previews page</a> (hotlinked; no files are stored in this repository).</p>

<h3>Desktop tour &middot; v1</h3>

<p align="center">
  <a href="https://equisdots.github.io/web/previews/clips/tour-v1-part01.mp4"><img src="https://equisdots.github.io/web/previews/clips/gif/tour-v1-part01.gif" alt="Desktop tour v1, clip 01" width="49%"></a>
  <a href="https://equisdots.github.io/web/previews/clips/tour-v1-part02.mp4"><img src="https://equisdots.github.io/web/previews/clips/gif/tour-v1-part02.gif" alt="Desktop tour v1, clip 02" width="49%"></a>
</p>

<p align="center">
  <a href="https://equisdots.github.io/web/previews/clips/tour-v1-part03.mp4"><img src="https://equisdots.github.io/web/previews/clips/gif/tour-v1-part03.gif" alt="Desktop tour v1, clip 03" width="49%"></a>
  <a href="https://equisdots.github.io/web/previews/clips/tour-v1-part04.mp4"><img src="https://equisdots.github.io/web/previews/clips/gif/tour-v1-part04.gif" alt="Desktop tour v1, clip 04" width="49%"></a>
</p>

<p align="center">
  <a href="https://equisdots.github.io/web/previews/clips/tour-v1-part05.mp4"><img src="https://equisdots.github.io/web/previews/clips/gif/tour-v1-part05.gif" alt="Desktop tour v1, clip 05" width="49%"></a>
  <a href="https://equisdots.github.io/web/previews/clips/tour-v1-part06.mp4"><img src="https://equisdots.github.io/web/previews/clips/gif/tour-v1-part06.gif" alt="Desktop tour v1, clip 06" width="49%"></a>
</p>

<p align="center">
  <a href="https://equisdots.github.io/web/previews/clips/tour-v1-part07.mp4"><img src="https://equisdots.github.io/web/previews/clips/gif/tour-v1-part07.gif" alt="Desktop tour v1, clip 07" width="49%"></a>
  <a href="https://equisdots.github.io/web/previews/clips/tour-v1-part08.mp4"><img src="https://equisdots.github.io/web/previews/clips/gif/tour-v1-part08.gif" alt="Desktop tour v1, clip 08" width="49%"></a>
</p>

<p align="center">
  <a href="https://equisdots.github.io/web/previews/clips/tour-v1-part09.mp4"><img src="https://equisdots.github.io/web/previews/clips/gif/tour-v1-part09.gif" alt="Desktop tour v1, clip 09" width="49%"></a>
  <a href="https://equisdots.github.io/web/previews/clips/tour-v1-part10.mp4"><img src="https://equisdots.github.io/web/previews/clips/gif/tour-v1-part10.gif" alt="Desktop tour v1, clip 10" width="49%"></a>
</p>

<p align="center">
  <a href="https://equisdots.github.io/web/previews/clips/tour-v1-part11.mp4"><img src="https://equisdots.github.io/web/previews/clips/gif/tour-v1-part11.gif" alt="Desktop tour v1, clip 11" width="49%"></a>
  <a href="https://equisdots.github.io/web/previews/clips/tour-v1-part12.mp4"><img src="https://equisdots.github.io/web/previews/clips/gif/tour-v1-part12.gif" alt="Desktop tour v1, clip 12" width="49%"></a>
</p>

<p align="center">
  <a href="https://equisdots.github.io/web/previews/clips/tour-v1-part13.mp4"><img src="https://equisdots.github.io/web/previews/clips/gif/tour-v1-part13.gif" alt="Desktop tour v1, clip 13" width="49%"></a>
  <a href="https://equisdots.github.io/web/previews/clips/tour-v1-part14.mp4"><img src="https://equisdots.github.io/web/previews/clips/gif/tour-v1-part14.gif" alt="Desktop tour v1, clip 14" width="49%"></a>
</p>

<h3>Desktop tour &middot; v2</h3>

<p align="center">
  <a href="https://equisdots.github.io/web/previews/clips/tour-v2-part01.mp4"><img src="https://equisdots.github.io/web/previews/clips/gif/tour-v2-part01.gif" alt="Desktop tour v2, clip 01" width="49%"></a>
  <a href="https://equisdots.github.io/web/previews/clips/tour-v2-part02.mp4"><img src="https://equisdots.github.io/web/previews/clips/gif/tour-v2-part02.gif" alt="Desktop tour v2, clip 02" width="49%"></a>
</p>

<p align="center">
  <a href="https://equisdots.github.io/web/previews/clips/tour-v2-part03.mp4"><img src="https://equisdots.github.io/web/previews/clips/gif/tour-v2-part03.gif" alt="Desktop tour v2, clip 03" width="49%"></a>
  <a href="https://equisdots.github.io/web/previews/clips/tour-v2-part04.mp4"><img src="https://equisdots.github.io/web/previews/clips/gif/tour-v2-part04.gif" alt="Desktop tour v2, clip 04" width="49%"></a>
</p>

</details>

---

## Quick Install

The official installer of the whole stack is
[`equisdots/dots`](https://github.com/equisdots/dots) (`./dots install`).

Standalone (this repo only):

<pre><code>git clone https://github.com/equisdots/hyprland.git
cd hyprland
chmod +x install.sh
./install.sh</code></pre>

<p><strong>Options:</strong> <code>--dotfiles-only</code> (config only), <code>--nvidia-only</code> (NVIDIA setup only).</p>

<p>The installer detects your distro and GPU, installs packages (Hyprland, kitty, rofi, and more), backs up existing configs, deploys the dotfiles, optionally configures NVIDIA Optimus and installs the SDDM theme, and installs kitty / Neovim from their own repos (`xscriptor-colors/terminal`, `xscriptor-colors/nvim`). Kitty, starship and Neovim then follow the palette through <a href="https://github.com/equisdots/theme-sync">equisdots/theme-sync</a>. The Quickshell shell, the palettes and the engines come from the org repos through <a href="https://github.com/equisdots/dots">equisdots/dots</a>: the installer runs <code>dots install</code> for you (fetching it on demand), so a single <code>./install.sh</code> leaves a complete desktop.</p>

<hr>

<h2>Features</h2>

<ul>
  <li><strong>Lua Config</strong> -- Hyprland 0.55+ <code>hyprland.lua</code> modular config (env, colors, keybinds, animations, rules, autostart) driven by the active palette.</li>
  <li><strong>12-Palette Theming</strong> -- <code>dock/palettes</code> drive the bar (equisdots/shell), window borders, kitty, starship, VS Code (color + icons) and Neovim in real time via <code>theme-sync</code> (equisdots/theme-sync).</li>
  <li><strong>System Scripts</strong> -- Session helpers: screenshots and recording, scale menu, monitor manager, GPU modes, idle modes, lock, reload and the monthly updater.</li>
  <li><strong>NVIDIA Optimus</strong> -- GPU mode switching (integrated/hybrid/nvidia) via keybind or Rofi.</li>
  <li><strong>Multi-Monitor</strong> -- Auto-detection at max refresh rate (Lua wildcard), Rofi-based position/resolution/refresh rate manager.</li>
  <li><strong>Static SDDM Login</strong> -- minimal black/white greeter from <a href="https://github.com/equisdots/login">equisdots/login</a> (no palette sync, no runtime sudo); window borders and the lock follow the palette instead.</li>
  <li><strong>Screen Recording</strong> -- GPU capture with separate desktop/mic audio channels.</li>
</ul>

<p>The Quickshell UI (bar, popups, panels, editor, lock) lives in
<a href="https://github.com/equisdots/shell">equisdots/shell</a>.</p>

<hr>

<h2>Customization</h2>

<p><code>SUPER + W</code> wallpaper picker &middot; <code>SUPER + SHIFT + S</code> / <code>SUPER + SHIFT + D</code> settings panel and bar editor (equisdots/shell)</p>
<p>See <a href="docs/hyprland-config.md">Hyprland Config</a> for file structure and <a href="docs/quick-reference.md">Quick Reference</a> for all keybinds.</p>

<hr>

<h2>Quick Reference</h2>

<p><code>SUPER + Return</code> Terminal &middot; <code>SUPER + D</code> Apps &middot; <code>SUPER + W</code> Wallpaper &middot; <code>SUPER + S</code> Calendar &middot; <code>SUPER + Space</code> Float &middot; <code>SUPER + L</code> Lock &middot; <code>Print</code> Screenshot &middot; <code>SUPER + Escape</code> Exit</p>

<p>See <a href="docs/quick-reference.md">full keybinding table</a>.</p>

<hr>

<h2>Structure</h2>

<pre><code>hyprland/
  install.sh                  Automated installer (installs kitty/nvim from their repos)
  uninstall.sh                Config removal
  config/hypr/                Hyprland Lua configs (hyprland.lua + modules,
                              hypridle.conf)
  config/rofi/                Launcher themes
  config/dunst/               Notification daemon
  config/cava/                Audio visualizer
  config/pam.d/               PAM service for the quickshell lock screen
  scripts/                    Shell scripts and daemons (reload.sh, lock.sh)</code></pre>

<hr>

<h2>Documentation</h2>

<ul>
  <li><a href="docs/installation.md">Installation</a> -- Full install, uninstall, and post-install guide</li>
  <li><a href="docs/quick-reference.md">Quick Reference</a> -- All keybindings and scripts at a glance</li>
  <li><a href="docs/scripts.md">Scripts</a> -- All shell scripts and daemons</li>
  <li><a href="docs/hyprland-config.md">Hyprland Configuration</a> -- Modular config structure and dynamic reload</li>
  <li><a href="docs/screenshot-recording.md">Screenshots &amp; Recording</a> -- Capture system with virtual audio</li>
  <li><a href="docs/neovim-config.md">Neovim Configuration</a> -- Editor setup from `xscriptor-colors/nvim` (palettes from the shell panel)</li>
  <li><a href="docs/multi-monitor.md">Multi-Monitor Setup</a> -- Display configuration guide</li>
  <li><a href="docs/gpu-mode.md">GPU Mode Switching</a> -- NVIDIA Optimus control</li>
</ul>

<p align="center">
  <a href="LICENSE">License</a> &middot;
  <a href="CODE_OF_CONDUCT.md">Code of Conduct</a> &middot;
  <a href="ROADMAP.md">Roadmap</a> &middot;
  <a href="CHANGELOG.md">Changelog</a> &middot;
  <a href="SECURITY.md">Security</a>
</p>

## Local checks

No CI: run the checks locally before pushing.

```bash
scripts/check.sh
```

- `luac -p` over every `config/**/*.lua` module.
- `bash -n` over every shell script (`shellcheck`, advisory, when installed).

<h2 align="center" id="related-repos">Related Repos</h2>
<ul>
  <li><a href="https://github.com/equisdots/shell">Shell</a> - Quickshell UI (bar, popups, panels, editor, lock)</li>
  <li><a href="https://github.com/equisdots/palettes">Palettes</a> - base16 palette data + schema</li>
  <li><a href="https://github.com/equisdots/theme-sync">theme-sync</a> - cross-app theming engine</li>
  <li><a href="https://github.com/equisdots/davincix">davincix</a> - wallpaper engine kernel</li>
  <li><a href="https://github.com/equisdots/dots">dots</a> - meta installer and updater</li>
  <li><a href="https://github.com/equisdots/timex">timex</a> - time, weather and calendar engine</li>
  <li><a href="https://github.com/equisdots/login">login</a> - static SDDM greeter</li>
  <li><a href="https://github.com/xscriptor-colors/terminal">Terminal</a> - Kitty + Starship synchronized dotfiles</li>
  <li><a href="https://github.com/xscriptor-colors/nvim">Nvim</a> - synchronized dotfiles</li>
  <li><a href="https://github.com/xscriptor-colors/vscode">VSCode</a> - synchronized dotfiles</li>
  <li><a href="https://github.com/xfetch-cli/">XFetch</a> - terminal tool shown in the previews</li>
</ul>
