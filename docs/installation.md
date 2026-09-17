# Installation

## Prerequisites

- **Distribution**: Arch Linux or derivatives (EndeavourOS, Manjaro, CachyOS, Garuda, X Arch Linux spin)
- **Kernel**: Linux 6.x or newer recommended
- **RAM**: 4 GB minimum, 8 GB or more recommended

## Quick Install

```bash
git clone https://github.com/equisdots/hyprland.git
cd hyprland
chmod +x install.sh
./install.sh
```

## Options

### NVIDIA Only
```bash
./install.sh --nvidia-only
```
Configures NVIDIA drivers (kernel parameters, mkinitcpio, DRM modeset, power management, envycontrol sudoers rule) without installing dotfiles or packages.

### Dotfiles Only
```bash
./install.sh --dotfiles-only
```
Deploys configuration files without package installation. Useful if packages are already installed or for manual setup.

### Non-interactive
```bash
./install.sh -y
```
Answers the prompts with the recommended defaults (NVIDIA setup, login theme,
monthly updater timer, service enablement). The wallpaper collection
(equisdots/background, release asset `background.zip`) is skipped, so it stays
manual/optional.

## What the Installer Does

1. Detects your distribution and GPU vendor
2. Installs required packages via AUR helper (yay/paru):
   - Hyprland and its Wayland ecosystem (xdg-desktop-portal, qt5/6-wayland, polkit)
   - QuickShell (QML shell), SwayOSD (on-screen display)
   - Utilities: kitty, dunst, grim, slurp, cliphist, gpu-screen-recorder, rofi, cava, and more
   - xwww: built from source (fork of awww with extra transitions) and installed to `/usr/local/bin` — the upstream `awww` package is not used
   - Fonts: Hack Nerd Font (downloaded separately), Noto Fonts, Noto Emoji
   - Themes: adw-gtk3, Papirus icons, Bibata cursors
   - NVIDIA: nvidia-utils, nvidia-settings, libva-nvidia-driver, egl-wayland, envycontrol
3. Backs up existing configurations to `~/.config/hyprland-backup-<timestamp>`
4. Deploys all configuration files
5. Configures NVIDIA (if applicable and confirmed):
   - Kernel parameters for GRUB and systemd-boot
   - mkinitcpio modules
   - DRM modeset and fbdev
   - Blacklists nouveau
   - Enables NVIDIA power management services
   - Optional: passwordless sudo rule for envycontrol
6. Downloads the optional wallpaper collection (equisdots/background release asset `background.zip`)
7. Optionally installs the static login theme (equisdots/login, SDDM)
8. Installs the shell payload through `equisdots/dots` (Quickshell UI, palettes,
   theme-sync, davincix, timex): runs `dots install` when available and fetches
   it on demand otherwise. Under `dots system` this step is skipped because the
   meta installer runs it right after.
9. Enables system services (NetworkManager, power-profiles-daemon, swayosd, pipewire, wireplumber)

## Uninstallation

```bash
./uninstall.sh
```

Removes all deployed configuration files and the login theme (delegated to equisdots/login). Optionally restores from backup. Does NOT remove installed packages or NVIDIA driver configuration.

## Post-Install

- Reboot is required (mandatory for NVIDIA driver changes)
- Select Hyprland from your display manager
- Default terminal: SUPER + Return
- App launcher: SUPER + D

The first boot will initialize the wallpaper daemon (davincix + xwww), pick a
random wallpaper and start all background services automatically.

## Wallpaper stack

Still wallpapers are applied by `davincix` through **xwww** (fork of awww with
the extra transitions). `install.sh` installs the checksum-verified prebuilt
release for `x86_64`/`aarch64` — only the two binaries davincix needs
(`xwww` + `xwww-daemon` in `/usr/local/bin`) — and falls back to a source build
(rust) when there is no release for the machine. `XWWW_VERSION` overrides the
release tag and `FORCE_XWWW=1` reinstalls an existing one; standalone
alternative: `equisdots/dots` (`scripts/install-xwww.sh`). Video wallpapers
need `mpvpaper`. The daemon is launched from `autostart.lua` and restarted by
the shell after theme changes.
