# rishot

A Wayland screenshot and annotation overlay built on [Quickshell](https://quickshell.outfoxxed.me/). You drag a region (or click a window or monitor), annotate it, and copy, save, or upload the result. rishot grew out of the screenshot surface of the [Ricelin](https://github.com/Gakuseei/Ricelin) Hyprland rice and is being pulled out into a standalone tool.

## Compositor support

Capture works on any wlroots or Wayland compositor that implements `wlr-screencopy` or `ext-image-copy-capture`. Region selection, monitor selection, and the full annotation toolset work everywhere capture does. Window-click selection (click a single window to grab just its frame) needs a per-compositor window query, and rishot only ships one for Hyprland (`hyprctl`), Sway (`swaymsg`) and Niri (`niri msg`). On any other compositor it degrades to region and monitor selection.

| Compositor | Capture | Region + monitor | Window-click |
| ---------- | ------- | ---------------- | ------------ |
| Hyprland   | yes     | yes              | yes          |
| Sway       | yes     | yes              | yes          |
| Niri       | yes     | yes              | yes          |
| Wayfire    | yes     | yes              | no (region + monitor only) |
| COSMIC     | yes     | yes              | no (region + monitor only) |
| river      | yes     | yes              | no (region + monitor only) |

Other wlroots compositors fall into the river row: capture plus region and monitor, no window-click.

## Install

### AUR (Arch, primary)

```sh
yay -S rishot-git
```

### One-line installer

```sh
curl -fsSL https://raw.githubusercontent.com/Gakuseei/rishot/main/install.sh | sh
```

Read the script before piping it to a shell. The download-inspect-run path:

```sh
curl -fsSL https://raw.githubusercontent.com/Gakuseei/rishot/main/install.sh -o install.sh
less install.sh
sh install.sh
```

The installer pulls runtime deps via your package manager where it can (pacman/yay/paru, apt, dnf, zypper, xbps; nix is detected but left for you to handle), drops rishot into `~/.local/share/rishot`, and symlinks the launcher into `~/.local/bin`. It never edits your compositor config; it prints the keybind line for you to add. quickshell is in the official repos on Arch (extra), recent Fedora (44+), Void, and Debian sid / Ubuntu 26.10. On older Fedora it comes from the COPR `errornointernet/quickshell`, which a Qt version mismatch can occasionally break.

### Manual

```sh
git clone https://github.com/Gakuseei/rishot.git
cd rishot
bin/rishot
```

`bin/rishot` finds its config dir from `$RISHOT_CONFIG_DIR`, then `~/.local/share/rishot/src`, `/usr/share/rishot/src`, `/usr/lib/rishot/src`, then `../src` next to the binary. So you can also drop `src/` at any of those prefixes and put `rishot` on PATH.

## Dependencies

Required:

- `quickshell` (the `qs` binary)
- Qt 6: declarative, svg, 5compat, wayland
- `wl-clipboard` (`wl-copy`), for copy-to-clipboard

Optional:

- `imagemagick`: stitching a multi-monitor capture into one image
- `cliphist`: recording copied shots into clipboard history
- `curl`: uploading
- `kdialog`: the save-as file dialog

## Running

```sh
rishot            # region: drag a box, or click a window to grab it
rishot monitor    # click a monitor to grab the whole output
```

From a checkout without installing, use `bin/rishot` instead.

## Keybinding

rishot does not register a global hotkey for you. Bind the command to a key in your compositor config yourself.

Hyprland (conf):

```
bind = , Print, exec, rishot
```

Hyprland (native Lua):

```lua
hl.bind("Print", hl.dsp.exec_cmd("rishot"))
```

Sway:

```
bindsym Print exec rishot
```

When you rebind from the in-app settings panel on Hyprland, the recorder autodetects whether your config is `hyprland.conf` or a native `hyprland.lua` and writes the matching form.

## Icons and Qt version

Icon centring inside the toolbar buttons needs Qt 6.10 or newer. On older Qt the icons fall back to box-centring, slightly off, but everything still works.

## Features

- Region and monitor selection
- Window highlight on hover (Hyprland, Sway, Niri)
- Annotation tools: rectangle, ellipse, line, arrow, pen, marker, text, blur
- Undo and redo
- Copy to clipboard, save to disk, upload

## Upload

Upload posts to `litterbox.catbox.moe` by default. The returned link is unguessable but **public** and expires after 72 hours; it is not authenticated or private. Point `RISHOT_UPLOAD` at your own endpoint to use a different host. For anything sensitive, use copy or save instead of upload.

## Environment variables

- `RISHOT_CONFIG_DIR`: override the Quickshell config dir (the one holding `shell.qml`)
- `RISHOT_SAVEDIR`: override the auto-save directory
- `RISHOT_UPLOAD`: override the upload endpoint (curl form-post target)
- `RISHOT_KEYBIND_FILE`: path to a keybind file rishot may write when you rebind from the settings panel
