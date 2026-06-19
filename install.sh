#!/bin/sh
# rishot installer: convenience path. The AUR package (rishot-git) is primary.
#
# Installs runtime deps via your package manager where it can, then drops rishot
# into ~/.local/share/rishot and symlinks the launcher into ~/.local/bin. It
# never edits your compositor config; it prints the keybind line for you to add.
#
# Safe to pipe: curl -fsSL .../install.sh | sh
# The whole body lives in main(), called on the last line, so a truncated
# download cannot execute a partial script.

set -eu

REPO_URL="https://github.com/Gakuseei/rishot.git"
PREFIX="${HOME}/.local/share/rishot"
BINDIR="${HOME}/.local/bin"

say() { printf '%s\n' "$*"; }
warn() { printf 'rishot: %s\n' "$*" >&2; }
die() { printf 'rishot: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# Pick a package manager. AUR helpers are preferred on Arch so quickshell can be
# pulled from the AUR if it is not already in extra.
detect_pm() {
	if have yay; then echo yay
	elif have paru; then echo paru
	elif have pacman; then echo pacman
	elif have apt-get; then echo apt
	elif have dnf; then echo dnf
	elif have zypper; then echo zypper
	elif have xbps-install; then echo xbps
	elif have nix-env; then echo nix
	else echo unknown
	fi
}

print_manual_deps() {
	say "Install these yourself, then re-run:"
	say "  required: quickshell, wl-clipboard, qt6-declarative, qt6-svg, qt6-5compat, qt6-wayland"
	say "  optional: imagemagick, cliphist, curl, kdialog"
	say "quickshell lives in: Arch extra, Debian/Ubuntu, Fedora COPR errornointernet/quickshell, NixOS, Void."
}

# Install deps. Returns non-zero if quickshell could not be handled, but never
# aborts the script; the file install still runs.
install_deps() {
	pm="$1"
	case "$pm" in
	yay | paru)
		say "Installing deps via $pm (quickshell from extra or AUR)…"
		"$pm" -S --needed --noconfirm quickshell wl-clipboard \
			qt6-declarative qt6-svg qt6-5compat qt6-wayland \
			imagemagick cliphist curl || return 1
		;;
	pacman)
		say "Installing deps via pacman…"
		sudo pacman -S --needed --noconfirm wl-clipboard \
			qt6-declarative qt6-svg qt6-5compat qt6-wayland \
			imagemagick curl || warn "some pacman deps failed"
		if ! have qs; then
			sudo pacman -S --needed --noconfirm quickshell 2>/dev/null || {
				warn "quickshell not in your repos; try an AUR helper (yay/paru) for 'quickshell'"
				return 1
			}
		fi
		;;
	apt)
		say "Installing deps via apt…"
		# quickshell is in Debian sid/testing and Ubuntu 26.10+ only (not stable
		# or older LTS) and pulls its own Qt6 QML runtime, so we do not hand-list
		# the Qt6 packages here. Names below are UNVERIFIED across releases; if
		# install fails, see the manual dep list and install quickshell yourself.
		sudo apt-get update || true
		sudo apt-get install -y quickshell wl-clipboard \
			libqt6svg6 qt6-wayland \
			imagemagick curl || return 1
		;;
	dnf)
		say "Installing deps via dnf…"
		sudo dnf install -y wl-clipboard \
			qt6-qtdeclarative qt6-qtsvg qt6-qt5compat qt6-qtwayland \
			ImageMagick curl || warn "some dnf deps failed"
		# quickshell is in official Fedora 44+/Rawhide; older Fedora needs the
		# COPR errornointernet/quickshell, which a Qt version mismatch can break.
		if ! sudo dnf install -y quickshell; then
			warn "quickshell not in your repos; trying COPR errornointernet/quickshell"
			sudo dnf -y copr enable errornointernet/quickshell || \
				warn "could not enable the quickshell COPR automatically"
			sudo dnf install -y quickshell || {
				warn "if 'qs' fails to start, check the COPR build vs your Qt6 version"
				return 1
			}
		fi
		;;
	zypper)
		say "Installing deps via zypper…"
		sudo zypper install -y wl-clipboard \
			qt6-declarative qt6-svg qt6-5compat qt6-wayland \
			ImageMagick curl || warn "some zypper deps failed"
		sudo zypper install -y quickshell || {
			warn "quickshell is not in base openSUSE repos; add an OBS repo first"
			warn "(e.g. home:AvengeMedia:danklinux), then install 'quickshell'"
			return 1
		}
		;;
	xbps)
		say "Installing deps via xbps…"
		# Void names the 5compat module qt6-qt5compat (not qt6-5compat).
		sudo xbps-install -Sy quickshell wl-clipboard \
			qt6-declarative qt6-svg qt6-qt5compat qt6-wayland \
			ImageMagick curl || return 1
		;;
	nix)
		warn "Nix detected. This installer will not mutate a Nix system."
		say "Add 'quickshell' and 'wl-clipboard' to your environment, e.g.:"
		say "  nix-shell -p quickshell wl-clipboard qt6.qtdeclarative"
		say "or add them to your home-manager / configuration.nix."
		return 1
		;;
	*)
		warn "unknown package manager; skipping automatic dep install"
		print_manual_deps
		return 1
		;;
	esac
}

# Place src/ at ~/.local/share/rishot/src and link the launcher onto PATH.
install_files() {
	mkdir -p "$PREFIX" "$BINDIR"

	# Locate this checkout: the dir holding install.sh, with a real src/bin.
	self_dir=""
	if [ -n "${0:-}" ] && [ -f "$0" ]; then
		self_dir=$(unset CDPATH && cd -- "$(dirname -- "$0")" && pwd)
	fi

	if [ -n "$self_dir" ] && [ -d "$self_dir/src" ] && [ -f "$self_dir/bin/rishot" ]; then
		say "Installing from checkout: $self_dir"
		rm -rf "${PREFIX:?}/src" "${PREFIX:?}/bin"
		cp -R "$self_dir/src" "$PREFIX/src"
		cp -R "$self_dir/bin" "$PREFIX/bin"
	else
		if ! have git; then die "git is required to fetch rishot (or run install.sh from a checkout)"; fi
		say "Fetching rishot into $PREFIX …"
		if [ -d "$PREFIX/.git" ]; then
			git -C "$PREFIX" pull --ff-only
		else
			rm -rf "${PREFIX:?}"
			git clone --depth 1 "$REPO_URL" "$PREFIX"
		fi
	fi

	[ -f "$PREFIX/src/shell.qml" ] || die "install looks wrong: $PREFIX/src/shell.qml missing"
	chmod 755 "$PREFIX/bin/rishot"
	ln -sf "$PREFIX/bin/rishot" "$BINDIR/rishot"

	# Desktop entry + icon so rishot shows up in app launchers.
	datadir="${XDG_DATA_HOME:-$HOME/.local/share}"
	icon_src=""
	if [ -n "$self_dir" ] && [ -f "$self_dir/packaging/rishot.svg" ]; then icon_src="$self_dir/packaging/rishot.svg"
	elif [ -f "$PREFIX/packaging/rishot.svg" ]; then icon_src="$PREFIX/packaging/rishot.svg"
	fi
	if [ -n "$icon_src" ]; then
		mkdir -p "$datadir/icons/hicolor/scalable/apps"
		cp "$icon_src" "$datadir/icons/hicolor/scalable/apps/rishot.svg"
	fi
	desk_src=""
	if [ -n "$self_dir" ] && [ -f "$self_dir/rishot.desktop" ]; then desk_src="$self_dir/rishot.desktop"
	elif [ -f "$PREFIX/rishot.desktop" ]; then desk_src="$PREFIX/rishot.desktop"
	fi
	if [ -n "$desk_src" ]; then
		mkdir -p "$datadir/applications"
		cp "$desk_src" "$datadir/applications/rishot.desktop"
	fi
}

check_path() {
	case ":${PATH}:" in
	*":${BINDIR}:"*) ;;
	*) warn "$BINDIR is not on your PATH; add it, e.g. in ~/.profile:"
		say "  export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
	esac
}

# Print the keybind line for the detected compositor. We do not edit configs.
print_keybind() {
	say ""
	say "Bind rishot to a key in your compositor config (it has no global hotkey):"
	if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
		say "  Hyprland (conf):  bind = , Print, exec, rishot"
		say "  Hyprland (lua):   hl.bind(\"Print\", hl.dsp.exec_cmd(\"rishot\"))"
	elif [ -n "${SWAYSOCK:-}" ]; then
		say "  Sway:             bindsym Print exec rishot"
	elif [ -n "${NIRI_SOCKET:-}" ]; then
		say "  Niri:             bind it to 'rishot' in your niri keybinds"
	else
		say "  Hyprland (conf):  bind = , Print, exec, rishot"
		say "  Hyprland (lua):   hl.bind(\"Print\", hl.dsp.exec_cmd(\"rishot\"))"
		say "  Sway:             bindsym Print exec rishot"
	fi
}

main() {
	say "rishot installer"
	say ""

	pm=$(detect_pm)
	say "Package manager: $pm"
	if ! install_deps "$pm"; then
		warn "dependencies need manual attention (see above); continuing with the file install"
	fi

	install_files
	check_path

	if ! have qs; then
		warn "'qs' (quickshell) is not on PATH yet; rishot needs it to run"
		print_manual_deps
	fi

	print_keybind

	say ""
	say "Done. Installed to $PREFIX, launcher at $BINDIR/rishot."
	say "Run it with:  rishot          (region / window)"
	say "         or:  rishot monitor  (whole output)"
}

main "$@"
