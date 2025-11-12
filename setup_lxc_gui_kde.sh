#!/bin/bash

# =======================================================================
#
# This script automates the complete setup of a KDE Plasma GUI environment in an existing LXC container.
# It installs KDE Plasma Desktop, SDDM display manager, XRDP for RDP access,
# Full AMD GPU support (ROCm, VAAPI, Vulkan), and configures all necessary services.
#
# Requirements:
# - Ubuntu 25.04
# - Unprivileged LXC container
# - Internet connection for package downloads
#
# Result: Fully functional KDE Plasma desktop with remote access capabilities
#
# SCRIPT FOR SETTING UP KDE PLASMA GUI IN EXISTING LXC CONTAINER
# =======================================================================

set -e  # Stop script on error

echo "🚀 STARTING KDE PLASMA SETUP IN EXISTING LXC CONTAINER"

# =======================================================================
# STEP 1: UPDATING SYSTEM AND INSTALLING PACKAGES
# =======================================================================

echo "📦 STEP 1.1: Updating system..."
apt update && apt upgrade -y

echo "🖥️  STEP 1.2: Installing base Xorg packages..."
apt install -y \
    xorg \
    xserver-xorg \
    xserver-xorg-core \
    xserver-xorg-input-all \
    xserver-xorg-input-libinput \
    xserver-xorg-input-wacom \
    xserver-xorg-legacy \
    xserver-xorg-video-all \
    xserver-xorg-video-amdgpu \
    xserver-xorg-video-ati \
    xserver-xorg-video-dummy \
    xserver-xorg-video-fbdev \
    xserver-xorg-video-radeon \
    xorg-docs-core \
    xorg-sgml-doctools

echo "🔧 STEP 1.3: Installing GPU support packages..."
apt install -y rocm-smi rocminfo libamdhip64-5 mesa-vulkan-drivers


echo "🔗 STEP 1.4: Installing XRDP packages..."
apt install -y \
    xrdp \
    xorgxrdp \
    libpipewire-0.3-modules-xrdp \
    pipewire-module-xrdp \
    python3-xkit


echo "🖥️  STEP 1.5: Installing KDE Plasma Desktop..."
# Using Ubuntu 24.04 default repositories with KDE Plasma 5.27
#apt install -y plasma-desktop plasma-nm plasma-pa kde-plasma-desktop
apt install -y plasma-desktop plasma-nm plasma-pa kde-plasma-desktop

echo "🔧 STEP 1.6: Installing additional packages..."
apt install -y \
    chromium \
    radeontop \
    vlc \
    libreoffice-calc

# =======================================================================
# ROCm PACKAGES INSTALLATION - ADDED FOR GPU SUPPORT
# =======================================================================
echo "🔧 STEP 1.8: Installing ROCm packages for GPU support..."
apt install -y rocm-smi rocminfo libamdhip64-5 mesa-vulkan-drivers


# Generate Russian locale
# echo "🌍 STEP 1.6.1: Generating Russian locale..."
# locale-gen ru_RU.UTF-8
# apt-get install -y locales
# sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
# locale-gen en_US.UTF-8
# update-locale LANG=en_US.UTF-8


# =======================================================================
# STEP 2: USER CONFIGURATION
# =======================================================================

echo "👤 STEP 2.1: Creating user..."
user="sip"
if ! id "$user" &>/dev/null; then
    useradd -m -s /bin/bash $user
    usermod -aG adm,audio,cdrom,dialout,xrdp,dip,fax,floppy,games,input,lp,plugdev,render,ssl-cert,sudo,tape,tty,video,voice,systemd-journal,systemd-network $user
    echo "$user:$user" | chpasswd
    echo "✅ User $user created successfully"
else
    echo "ℹ️  User $user already exists, skipping creation"
fi

echo "🔐 STEP 2.2: Configuring sudo..."
sudo_file="/etc/sudoers.d/$user"
if [ ! -f "$sudo_file" ]; then
    echo "$user ALL=(ALL) NOPASSWD:ALL" > "$sudo_file"
    echo "✅ Sudo configuration created for $user"
else
    echo "ℹ️  Sudo configuration already exists for $user"
fi

# =======================================================================
# STEP 3: CREATING CUSTOM SYSTEMD UNITS HOST DISPLAY
# =======================================================================

# echo "🔧 STEP 3.1: Creating Xorg Headless service..."
cat > /etc/systemd/system/xorg-headless.service << 'XORG_EOF'
[Unit]
Description=Headless Xorg on VT7
After=systemd-user-sessions.service
Before=plasma-headless@.service

[Service]
User=root
Group=root
Environment=DISPLAY=:0
PermissionsStartOnly=true

ExecStartPre=/bin/mkdir -p /tmp/.X11-unix
ExecStartPre=/bin/chown root:root /tmp/.X11-unix
ExecStartPre=/bin/chmod 1777 /tmp/.X11-unix

ExecStart=/usr/lib/xorg/Xorg :0 vt7 -config /etc/X11/xorg.conf.d/10-headless-amdgpu.conf -noreset -nolisten tcp -ac

Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
XORG_EOF

echo "🔧 STEP 3.2: Creating Plasma Headless service..."
cat > /etc/systemd/system/plasma-headless@.service << 'PLASMA_EOF'
[Unit]
Description=KDE Plasma Headless Session (%i)
After=network-online.target xorg-headless.service
Wants=network-online.target
Requires=xorg-headless.service

[Service]
Type=simple
User=%i
Group=%i
PAMName=login
# Environment variables for KDE Plasma
Environment=DISPLAY=:0
Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
Environment=QT_QPA_PLATFORM=xcb
Environment=DESKTOP_SESSION=plasma
Environment=KDE_FULL_SESSION=true
Environment=XDG_SESSION_TYPE=x11
Environment=XDG_SESSION_DESKTOP=KDE
Environment=XDG_CURRENT_DESKTOP=KDE
Environment=QT_QPA_PLATFORMTHEME=KDE
Environment=LANG=ru_RU.UTF-8
Environment=LC_ALL=ru_RU.UTF-8
PermissionsStartOnly=true

ExecStartPre=/bin/sh -c 'U=$(id -u %i); install -d -m700 -o %i -g %i /run/user/$U'
ExecStartPre=/bin/sh -lc 'for i in $(seq 1 100); do [ -S /tmp/.X11-unix/X0 ] && xdpyinfo -display :0 >/dev/null 2>&1 && exit 0; sleep 0.2; done; echo "X :0 not ready"; exit 1'
ExecStart=/bin/sh -lc 'exec dbus-run-session startplasma-x11'

Restart=on-failure
RestartSec=1
TimeoutStartSec=25

[Install]
WantedBy=multi-user.target
PLASMA_EOF

# =======================================================================
# STEP 4: CREATING XORG CONFIGURATION
# =======================================================================

echo "��️  STEP 4: Creating Xorg configuration..."
cat > /etc/X11/xorg.conf.d/10-headless-amdgpu.conf << 'XORG_CONF_EOF'
# /etc/X11/xorg.conf.d/10-headless-amdgpu.conf
Section "Monitor"
    Identifier "Monitor0"
    Option "DPMS" "false"
    Modeline "1920x1080_60.00" 173.00 1920 2048 2248 2576 1080 1083 1088 1120 -hsync +vsync
EndSection

Section "Device"
    Identifier "AMDgpu0"
    Driver "amdgpu"
    Option "AccelMethod" "glamor"
    Option "TearFree" "true"
EndSection

Section "Screen"
    Identifier "Screen0"
    Device "AMDgpu0"
    Monitor "Monitor0"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1920x1080_60.00"
    EndSubSection
EndSection

Section "ServerLayout"
    Identifier "Layout0"
    Screen 0 "Screen0"
EndSection
XORG_CONF_EOF

# =======================================================================
# STEP 4.1: CREATING XRDP IGPU CONFIGURATION
# =======================================================================
echo "🔧 STEP 4.1: Creating Xorg configuration for XRDP..."
sed -i '/^Section "Device"$/,/^EndSection$/c\
Section "Device"\
    Identifier "Video Card (xrdpdev)"\
    Driver "xrdpdev"\
    Option "DRMDevice" "/dev/dri/renderD128"\
    Option "DRI3" "1"\
    Option "DRMAllowList" "amdgpu"\
    Option "AccelMethod" "glamor"\
    Option "TearFree" "true"\
EndSection' /etc/X11/xrdp/xorg.conf


# =======================================================================
# COMPLETION
# =======================================================================

echo "🔧 STEP 5.1: Setting up complete GUI desktop environment variables..."
# ## ============================================================================
# ## GPU & GRAPHICS DRIVERS - AMD Radeon
# ## ============================================================================

## Additional environment variables for KDE Plasma and GPU support
## This ensures variables are available for all users

# Vulkan ICD for AMD GPU (Steam snap compatibility)
export VK_ICD_FILENAMES="/usr/share/vulkan/icd.d/radeon_icd.x86_64.json"
export VK_DRIVER_FILES="/usr/share/vulkan/icd.d/radeon_icd.x86_64.json"
export AMD_VK_USE_PIPELINE_CACHE=1

export LIBVA_DRIVER_NAME=radeonsi
export VDPAU_DRIVER=radeonsi

## Mesa/OpenGL for AMD
export MESA_GL_VERSION_OVERRIDE=4.6
export MESA_GLSL_VERSION_OVERRIDE=460
export MESA_DRI_DRIVER=radeonsi

## ============================================================================
## DISPLAY & DESKTOP ENVIRONMENT
## ============================================================================
## X11 settings for headless operation
export DISPLAY=:0
export XAUTHORITY=/home/$user/.Xauthority

## KDE Plasma Desktop settings
export DESKTOP_SESSION=plasma
export KDE_FULL_SESSION=true
export XDG_SESSION_TYPE=x11
export XDG_SESSION_DESKTOP=KDE
export XDG_CURRENT_DESKTOP=KDE

## Qt5 settings for KDE Plasma 5.27
export QT_QPA_PLATFORM=xcb
export QT_QPA_PLATFORMTHEME=KDE
export QT_X11_NO_MITSHM=1

## KDE specific settings
export KDEDIRS=/usr
export KDE_SESSION_VERSION=5

## Locale settings (Russian)
#export LANG=ru_RU.UTF-8
#export LC_ALL=ru_RU.UTF-8
#export LANGUAGE=ru_RU:ru


# =======================================================================
# STEP 6: CONFIGURING AND STARTING SERVICES
# =======================================================================

#echo "⚙️  STEP 6.1: Reloading systemd..."
#systemctl daemon-reload

# echo "▶️  STEP 6.2: Enabling and starting services..."
# systemctl enable xorg-headless.service
# systemctl start xorg-headless.service

# echo "▶️  STEP 6.4: Enabling KDE Plasma for user sip..."
# systemctl enable plasma-headless@$user.service
# systemctl start plasma-headless@$user.service

# =======================================================================
# NOMACHINE REMOTE DESKTOP INSTALLATION
# =======================================================================
# echo "🔧 STEP 1.8.2: Installing NoMachine remote desktop server..."

# # Advanced NoMachine installer (downloads latest .deb for current architecture)
# # Resilient to redirects/cookies and provides detailed logs.

# ARCH="$(dpkg --print-architecture)"    # amd64 / arm64 etc.
# UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Safari/537.36'
# ACCEPT_LANG='en;q=0.9,ru;q=0.8'
# TMPDIR="$(mktemp -d -t nomx-XXXXXX)"
# CJ="$TMPDIR/cookies.txt"
# PRIMARY_URL="https://www.nomachine.com/download/download&id=1"
# ALT_URL="https://download.nomachine.com/download/?id=1&platform=linux"
# TS="$(date +%s)" # cache-bust

# # Ensure curl/ca-certificates are available
# if ! command -v curl >/dev/null 2>&1; then
#   apt-get update -y >/dev/null 2>&1
#   apt-get install -y curl ca-certificates >/dev/null 2>&1
# fi

# log() { echo "$@"; }

# fetch_html () {
#   local url="$1"
#   log "   -> GET $url"
#   # Separate cookie jar for each run; limit redirects; set headers
#   curl -fsSL \
#     --max-redirs 20 \
#     -A "$UA" \
#     -H "Accept-Language: $ACCEPT_LANG" \
#     -e "https://www.nomachine.com/download" \
#     -c "$CJ" -b "$CJ" \
#     -m 30 \
#     "$url"
# }

# parse_link_id() {
#   # Search specifically for <a id="link_download" href="...deb">
#   sed -n 's/.*id="link_download" href="\([^"]*\.deb\)".*/\1/p' | head -n1
# }

# parse_link_arch() {
#   # Fallback: any link to nomachine_*_ARCH.deb
#   sed -n "s|.*href=\"\\([^\"]*nomachine_[^\"]*_${ARCH}\\.deb\\)\".*|\\1|p" | head -n1
# }

# follow_meta_refresh() {
#   sed -n 's/.*http-equiv="refresh".*url=\([^"]*\)".*/\1/p' | head -n1
# }

# log " - Fetching latest NoMachine .deb link..."
# DL_URL=""

# # 1) Primary URL with cache-bust
# HTML="$(fetch_html "${PRIMARY_URL}&_ts=${TS}" 2>/dev/null || true)"
# if [[ -z "${HTML:-}" ]]; then
#   log "   ! Primary returned empty. Trying ALT..."
# else
#   DL_URL="$(printf '%s\n' "$HTML" | parse_link_id 2>/dev/null || true)"
#   [[ -n "$DL_URL" ]] && log "   -> Parsed via id=link_download (primary)"
# fi

# # 2) If not found - try meta refresh on primary
# if [[ -z "$DL_URL" && -n "${HTML:-}" ]]; then
#   META_URL="$(printf '%s\n' "$HTML" | follow_meta_refresh 2>/dev/null || true)"
#   if [[ -n "$META_URL" ]]; then
#     log "   -> Following meta refresh (primary): $META_URL"
#     HTML2="$(fetch_html "${META_URL}&_ts=${TS}" 2>/dev/null || true)"
#     if [[ -n "${HTML2:-}" ]]; then
#       DL_URL="$(printf '%s\n' "$HTML2" | parse_link_id 2>/dev/null || true)"
#       [[ -n "$DL_URL" ]] && log "   -> Parsed via id=link_download (meta)"
#       [[ -z "$DL_URL" ]] && DL_URL="$(printf '%s\n' "$HTML2" | parse_link_arch 2>/dev/null || true)"
#       [[ -n "$DL_URL" ]] && log "   -> Parsed via *_${ARCH}.deb (meta)"
#     fi
#   fi
# fi

# # 3) If still empty - try ALT URL
# if [[ -z "$DL_URL" ]]; then
#   HTML_ALT="$(fetch_html "${ALT_URL}&_ts=${TS}" 2>/dev/null || true)"
#   if [[ -n "${HTML_ALT:-}" ]]; then
#     DL_URL="$(printf '%s\n' "$HTML_ALT" | parse_link_id 2>/dev/null || true)"
#     [[ -n "$DL_URL" ]] && log "   -> Parsed via id=link_download (alt)"
#     if [[ -z "$DL_URL" ]]; then
#       log "   ! Fallback on ALT: search for *_${ARCH}.deb"
#       DL_URL="$(printf '%s\n' "$HTML_ALT" | parse_link_arch 2>/dev/null || true)"
#     fi
#   fi
# fi

# # 4) Final validation
# if [[ -z "$DL_URL" ]]; then
#   log " ! ERROR: could not parse a .deb URL for arch: ${ARCH}"
#   log "   Tip: check network connectivity and site availability"
#   rm -rf "$TMPDIR"
#   exit 1
# fi

# # 5) If id-link gave wrong arch - filter it
# if ! [[ "$DL_URL" =~ _${ARCH}\.deb$ ]]; then
#   log "   ! Parsed URL arch mismatch; searching for matching *_${ARCH}.deb..."
#   CANDIDATE="$(printf '%s\n' "${HTML:-}${HTML2:-}${HTML_ALT:-}" | parse_link_arch 2>/dev/null || true)"
#   if [[ -n "$CANDIDATE" ]]; then
#     DL_URL="$CANDIDATE"
#     log "   -> Using: $DL_URL"
#   fi
# fi

# log " - Found: $DL_URL"
# PKG="$TMPDIR/$(basename "$DL_URL")"

# log " - Downloading package..."
# curl -fSL --max-redirs 20 -A "$UA" -H "Accept-Language: $ACCEPT_LANG" -c "$CJ" -b "$CJ" -m 180 -o "$PKG" "$DL_URL"

# # 6) Installation
# if ! dpkg -i "$PKG"; then
#   log " - dpkg failed, resolving dependencies..."
#   apt-get update -y >/dev/null 2>&1
#   apt-get -f install -y >/dev/null 2>&1
#   # Retry if needed
#   dpkg -i "$PKG" 2>/dev/null || true
# fi

# log " - Cleaning up..."
# rm -rf "$TMPDIR"

# log " - NoMachine installed successfully."

# =======================================================================
# CONFIGURING KDE PLASMA 5.27 DESKTOP ENVIRONMENT
# =======================================================================

# Configure NetworkManager for proper network connectivity detection
echo "🌐 STEP 1.7: Configuring NetworkManager for Discover..."
# Stop systemd-networkd and let NetworkManager manage interfaces
systemctl stop systemd-networkd systemd-networkd.socket || true
systemctl disable systemd-networkd systemd-networkd.socket || true
# Remove systemd-networkd configuration
rm -f /etc/systemd/network/eth0.network
# Configure NetworkManager to manage all devices
sed -i 's/managed=false/managed=true/' /etc/NetworkManager/NetworkManager.conf
echo -e '\n[keyfile]\nunmanaged-devices=none' >> /etc/NetworkManager/NetworkManager.conf

# Fix NetworkManager authorization issues in LXC
echo "🔧 STEP 1.8: Fixing NetworkManager authorization issues..."
sed -i '/\[main\]/a auth-polkit=false' /etc/NetworkManager/NetworkManager.conf
echo "✅ NetworkManager authorization fixed (auth-polkit=false)"

# Restart NetworkManager
systemctl restart NetworkManager


echo "🔧 STEP 5.3: Configuring KDE Plasma 5.27 desktop environment..."

      cat > /etc/polkit-1/rules.d/50-plasma-lxc-soft.rules <<EOF
// Soft permissions for KDE Plasma in unprivileged LXC (ES5-compatible).
// IMPORTANT: no ES6 (no Set/startsWith), no mandatory active/local checks.

var USER = "$user";

function session_ok(subject) {
  // In LXC, subject.active/subject.local are often undefined.
  var activeOK = (subject.active === undefined) ? true : subject.active;
  var localOK  = (subject.local  === undefined) ? true : subject.local;
  return activeOK && localOK;
}

polkit.addRule(function(action, subject) {
  // Limit actions only to the specified user.
  if (subject.user !== USER) {
    return;
  }

  // If you want to additionally restrict to an active "local" session, uncomment:
  // if (!session_ok(subject)) return;

  var id = action.id;

  // ─────────── NetworkManager (soft) ───────────
  var NM_TOGGLES = [
    "org.freedesktop.NetworkManager.enable-disable-network",
    "org.freedesktop.NetworkManager.enable-disable-wifi",
    "org.freedesktop.NetworkManager.enable-disable-wwan"
  ];
  if (NM_TOGGLES.indexOf(id) !== -1) {
    return polkit.Result.YES;
  }

  // Allow modifying ONLY own connections.
  if (id === "org.freedesktop.NetworkManager.settings.modify.own") {
    return polkit.Result.YES;
  }

  // Do NOT open full network-control intentionally (leaving to system policy)
  // if (id === "org.freedesktop.NetworkManager.network-control") return;

  // ─────────── UDisks2 (mount/unmount) ───────────
  // Prefix check without startsWith:
  if (id.indexOf("org.freedesktop.udisks2.filesystem-mount") === 0 ||
      id.indexOf("org.freedesktop.udisks2.filesystem-unmount") === 0) {
    return polkit.Result.YES;
  }
  // If necessary, add LUKS unlock:
  // if (id === "org.freedesktop.udisks2.encrypted-unlock") return polkit.Result.YES;

  // ─────────── PackageKit / Discover ───────────
  var PK_ALLOW = [
    "org.freedesktop.packagekit.package-install",
    "org.freedesktop.packagekit.package-install-untrusted",
    "org.freedesktop.packagekit.package-remove",
    "org.freedesktop.packagekit.package-reinstall",
    "org.freedesktop.packagekit.package-downgrade",
    "org.freedesktop.packagekit.system-update",
    "org.freedesktop.packagekit.trigger-offline-update",
    "org.freedesktop.packagekit.trigger-offline-upgrade",
    "org.freedesktop.packagekit.upgrade-system",
    "org.freedesktop.packagekit.system-sources-configure",
    "org.freedesktop.packagekit.system-sources-refresh",
    "org.freedesktop.packagekit.system-trust-signing-key",
    // optional (remove if not needed):
    "org.freedesktop.packagekit.system-network-proxy-configure",
    "org.freedesktop.packagekit.clear-offline-update",
    "org.freedesktop.packagekit.cancel-foreign",
    "org.freedesktop.packagekit.repair-system"
  ];
  if (PK_ALLOW.indexOf(id) !== -1) {
    return polkit.Result.YES;
  }

  // ─────────── Snap (snapd) ───────────
  var SNAP_ALLOW = [
    "io.snapcraft.snapd.login",
    "io.snapcraft.snapd.manage",
    "io.snapcraft.snapd.manage-configuration",
    "io.snapcraft.snapd.manage-interfaces"
    // Do NOT add: "io.snapcraft.snapd.manage-fde"
  ];
  if (SNAP_ALLOW.indexOf(id) !== -1) {
    return polkit.Result.YES;
  }

  // ─────────── Flatpak ───────────
  var FLATPAK_ALLOW = [
    "org.freedesktop.Flatpak.app-install",
    "org.freedesktop.Flatpak.app-uninstall",
    "org.freedesktop.Flatpak.app-update",
    "org.freedesktop.Flatpak.runtime-install",
    "org.freedesktop.Flatpak.runtime-uninstall",
    "org.freedesktop.Flatpak.runtime-update",
    "org.freedesktop.Flatpak.install-bundle",
    "org.freedesktop.Flatpak.appstream-update",
    "org.freedesktop.Flatpak.metadata-update",
    "org.freedesktop.Flatpak.configure",
    "org.freedesktop.Flatpak.configure-remote",
    "org.freedesktop.Flatpak.modify-repo",
    "org.freedesktop.Flatpak.update-remote"
  ];
  if (FLATPAK_ALLOW.indexOf(id) !== -1) {
    return polkit.Result.YES;
  }

  // Everything else — default policy (password/deny).
  return;
});
EOF

cat > /etc/polkit-1/rules.d/50-network-manager.rules <<EOL
polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.NetworkManager.network-control" &&
        subject.isInGroup("sudo")) {
        return polkit.Result.YES;
    }
});
EOL

cat > /etc/polkit-1/rules.d/51-power-management.rules <<EOL
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.login1.reboot" ||
         action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
         action.id == "org.freedesktop.login1.power-off" ||
         action.id == "org.freedesktop.login1.power-off-multiple-sessions") &&
        subject.isInGroup("sudo")) {
        return polkit.Result.YES;
    }
});
EOL

      echo "Configuring kwinrc"
      su - $user -c "kwriteconfig5 --file kwinrc --group \$Version --key update_info update_info=kwin.upd:replace-scalein-with-scale,kwin.upd:port-minimizeanimation-effect-to-js,kwin.upd:port-scale-effect-to-js,kwin.upd:port-dimscreen-effect-to-js,kwin.upd:auto-bordersize,kwin.upd:animation-speed,kwin.upd:desktop-grid-click-behavior,kwin.upd:no-swap-encourage,kwin.upd:make-translucency-effect-disabled-by-default,kwin.upd:remove-flip-switch-effect,kwin.upd:remove-cover-switch-effect,kwin.upd:remove-cubeslide-effect,kwin.upd:remove-xrender-backend,kwin.upd:enable-scale-effect-by-default,kwin.upd:overview-group-plugin-id,kwin.upd:animation-speed-cleanup,kwin.upd:replace-cascaded-zerocornered"

      echo "Configuring Breeze Dark theme"
      su - $user -c "kwriteconfig5 --group General --key ColorScheme BreezeDark"
      su - $user -c "kwriteconfig5 --file ~/.config/plasmarc --group Theme --key name breeze-dark"

      echo "Configuring Screen Animations"
      su - $user -c "kwriteconfig5 --file ~/.config/kwinrc --group Compositing --key Enabled true"
      su - $user -c "kwriteconfig5 --file ~/.config/kwinrc --group Plugins --key wobblywindowsEnabled true"

      echo "Cleaning container"
      su - $user -c "
           sudo apt purge -y bluez pulseaudio-module-bluetooth;
           sudo apt purge -y powerdevil upower;
           sudo systemctl daemon-reload;
           sudo systemctl enable sddm;
           sudo apt -y autoremove"


      echo "Uninstalling khelpcenter"
      su - $user -c "
           sudo apt purge -y khelpcenter"

      echo "Rebooting"
      su - $user -c "sudo reboot now"
