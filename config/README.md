# Desktop config (Fedora 44 + Hyprland)

Snapshot of the daily-driver setup from the `tide` PC. Only things used day to day are
included; old i3/yabai/aerospace/alacritty/zathura configs, `.bak` files, caches and logs
were left out on purpose.

## What is in here

| Path in this folder | Install to | What it is |
|---|---|---|
| `hypr/` | `~/.config/hypr/` | Hyprland, hyprlock, hyprpaper, wallpaper |
| `waybar/` | `~/.config/waybar/` | Bottom bar + `popup.sh` (floating TUI popups from bar clicks) |
| `kitty/` | `~/.config/kitty/` | Terminal + "moss" green theme |
| `nvim/` | `~/.config/nvim/` | Neovim config, `moss` colorscheme, `paint.lua` |
| `fontconfig/conf.d/` | `~/.config/fontconfig/conf.d/` | Verdana hinting rule |
| `wireplumber/wireplumber.conf.d/` | `~/.config/wireplumber/wireplumber.conf.d/` | Keeps cameras out of PipeWire (needed for OBS + V4L2) |
| `mimeapps.list` | `~/.config/mimeapps.list` | Default apps (Chrome, VLC) |
| `shell/bashrc`, `bash_profile`, `tmux.conf`, `gitconfig` | `~/.bashrc`, `~/.bash_profile`, `~/.tmux.conf`, `~/.gitconfig` | Shell, tmux (prefix `C-a`), git identity |
| `camera/` | `~/camera/` | Sony ZV-E10 → OBS scripts (see below) |
| `obs-studio/` | `~/.var/app/com.obsproject.Studio/config/obs-studio/` | OBS scene collection + profile settings |

## 1. Packages (Fedora)

```bash
# Hyprland desktop
sudo dnf install -y hyprland hyprlock hypridle hyprpaper waybar wofi \
    xdg-desktop-portal-hyprland xdg-desktop-portal-wlr \
    grim slurp wl-clipboard playerctl brightnessctl pulseaudio-utils \
    NetworkManager-tui network-manager-applet wiremix

# Terminal / editor / shell tools
sudo dnf install -y kitty neovim tmux git v4l-utils mpv vlc

# Fonts (waybar uses Hack; if this package name is not found, run: dnf search hack fonts)
sudo dnf install -y source-foundry-hack-fonts

# Browser
# google-chrome-stable: install from https://www.google.com/chrome/ (default browser in mimeapps.list)
```

Notes:
- `hyprland.conf` autostarts `dunst` and `nm-applet`. `dunst` was **not** installed on the
  original machine, so notifications were never running. Run `sudo dnf install dunst` if you
  want them (or remove the `exec-once = dunst` line).
- `hypridle` is autostarted but there is no `hypridle.conf` in the original setup; it runs
  with defaults. Add `~/.config/hypr/hypridle.conf` if you want custom idle/lock timeouts.
- `bluetui` (used by the bluetooth bar click) is not in the Fedora repos:
  `cargo install bluetui` (or download a release) and make sure it ends up in `~/.local/bin/`.
- `~/.local/bin` must be in `PATH` (the provided `bashrc` does this).

## 2. Fonts

- **Hack** – waybar font (`style.css`).
- **Verdana** – proprietary; copy the `.ttf` files from the old PC
  (`~/.local/share/fonts/verdana/`) to the same path, then `fc-cache -f`.
  The fontconfig rule here only adjusts hinting for it.

## 3. Install the configs

From this folder:

```bash
mkdir -p ~/.config
cp -r hypr waybar kitty nvim fontconfig wireplumber ~/.config/
cp mimeapps.list ~/.config/
chmod +x ~/.config/waybar/popup.sh

cp shell/bashrc ~/.bashrc
cp shell/bash_profile ~/.bash_profile
cp shell/tmux.conf ~/.tmux.conf
cp shell/gitconfig ~/.gitconfig        # contains name/email; edit if it should differ

mkdir -p ~/camera && cp camera/*.sh ~/camera/ && chmod +x ~/camera/*.sh

systemctl --user restart wireplumber   # picks up the no-cameras rule
```

### Monitors – must edit
`hypr/hyprland.conf` is written for this desk setup:

```
monitor=HDMI-A-2,preferred,0x0,1,transform,1     # rotated (portrait) primary
monitor=HDMI-A-1,preferred,1080x0,1              # secondary, to its right
workspace = 1 -> HDMI-A-2, workspaces 2-10 -> HDMI-A-1
```
and `hyprpaper.conf` names the same two outputs. On the new PC run `hyprctl monitors`,
then replace the output names / transform / offsets in both files (and delete the
`workspace = N, monitor:` lines if there is only one screen).

### Other things baked into the config
- Keyboard layout `gb`, Caps Lock → Ctrl (`kb_options = ctrl:nocaps`).
- Mod key is **Alt**, i3-style bindings (hjkl focus/move, `Alt+R` resize mode, `Alt+1..0` workspaces,
  `Alt+D` wofi, `Alt+Return` kitty (via XWayland so the drawing-tablet pen works), `Ctrl+Alt+L` lock).
- Screenshots (`Print`, `Alt+Print`, `Shift+Print`, `Ctrl+…` to clipboard) save to `~/Pictures/`.
- `waybar` is at the bottom; clicking volume / bluetooth / network opens a floating kitty with
  `wiremix` / `bluetui` / `nmtui-connect`.
- Neovim expects ESP-IDF's clangd under `~/.espressif/tools/esp-clangd/esp-21.1.3_20260408/…`.
  If you don't do ESP32 work, delete the "lsp" block in `nvim/init.lua`; otherwise install
  ESP-IDF via `eim` and update that version string. Neovim ≥ 0.12 is needed (`vim.pack`).
  The first start will fetch `gruber-darker.nvim` (the active theme is the local `moss`).

## 4. Camera + OBS (Sony ZV-E10 as webcam)

OBS is the **Flatpak** version with plugins; the scripts assume that.

```bash
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.obsproject.Studio \
    com.obsproject.Studio.Plugin.AitumMultistream \
    com.obsproject.Studio.Plugin.VerticalCanvas \
    com.obsproject.Studio.Plugin.DroidCam
```

Run OBS once so it creates its config dir, close it, then copy the scene/profile:

```bash
cp -r obs-studio/basic ~/.var/app/com.obsproject.Studio/config/obs-studio/
```
Then in OBS: **Tools → WebSocket Server Settings → Enable** (the scripts read the port and
password from OBS's own config). Not included on purpose because they hold secrets:
stream keys / RTMP targets (`service.json`, `obs-multi-rtmp.json`) and the websocket
password – re-enter those by hand. The scene's V4L2 source points at `/dev/video1` and an
audio input for a Shure MV7; re-select the devices if they differ on the new PC.

### Camera scripts (`~/camera/`)
- `reconnect-camera.sh` – the main one. Re-points OBS at the ZV-E10 without stopping the
  stream. `--check` only reports state; `--reset` power-cycles the camera's USB port first (sudo).
  Requires `v4l-utils`, `python3`, and the camera set to **USB Streaming** mode.
  Edit `CAM_NAME` / `CAM_VENDOR` / `CAM_STREAM_PRODUCT` at the top for a different camera.
- `restart-camera.sh` – kills OBS and reloads the `uvcvideo` kernel module (sudo).

Left out: `fix-camera.sh` (hard-coded to this machine's USB/PCI address
`0000:0e:00.0-1`, so it would not work elsewhere) and `printer_stream.py` (Bambu printer
camera, contains the printer's access code).

## 5. GPU / drivers (only if the new PC matches)
The original machine uses NVIDIA (`akmod-nvidia`, RPM Fusion) and Mesa for the iGPU. Enable
RPM Fusion first, then `sudo dnf install akmod-nvidia`. Skip on AMD/Intel-only machines.

## 6. Tailscale / SSH (for remote access)
```bash
sudo dnf install -y openssh-server
sudo systemctl enable --now sshd
sudo dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo
sudo dnf install -y tailscale && sudo systemctl enable --now tailscaled
sudo tailscale up
sudo firewall-cmd --permanent --zone=trusted --add-interface=tailscale0 && sudo firewall-cmd --reload
```
Remember each `~/.ssh/config` entry needs its own `Host` line.

## 7. Log in
Select **Hyprland** from the display manager (GDM/ly), or run `Hyprland` from a TTY.
After the first login: `hyprctl reload` (`Alt+Shift+C`) once monitor names are fixed.
