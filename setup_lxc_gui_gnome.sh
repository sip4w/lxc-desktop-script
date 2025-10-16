# =======================================================================
# SETUP LXC GNOME SCRIPT - VERSION 1.2 (UBUNTU GNOME DESKTOP)
# Status: GNOME Desktop with full GPU support (ROCm + VAAPI + Vulkan) and remote access
# =======================================================================
# =======================================================================
#!/bin/bash

# =======================================================================
#
# This script automates the complete setup of a GNOME GUI environment in an existing LXC container.
# It installs Ubuntu GNOME Desktop, XRDP for RDP access, multiple VNC servers,
# Full AMD GPU support (ROCm, VAAPI, Vulkan), and configures all necessary services.
#
# Requirements:
# - Ubuntu 24.04
# - Unprivileged LXC container
# - Internet connection for package downloads
# This section updates the system and installs all necessary packages for GUI support
#
# Result: Fully functional GNOME desktop with remote access capabilities
#
# SCRIPT FOR SETTING UP GNOME GUI IN EXISTING LXC CONTAINER
# Based on setup_lxc_gui_v1.2.sh
# Решение первоначальной проблемы:
# The original error "Steam needs to be online to update. Please confirm your network connection" was caused by:
# Steam was trying to use IPv6 to download updates
# IPv6 is not available in the container
# After launching Steam directly (bypassing the bootstrap), the client was able to connect via IPv4
# =======================================================================

set -e  # Stop script on error

echo "🚀 STARTING GNOME SETUP IN EXISTING LXC CONTAINER"

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
    xserver-xorg-video-intel \
    xserver-xorg-video-qxl \
    xserver-xorg-video-radeon \
    xserver-xorg-video-vesa \
    xorg-docs-core \
    xorg-sgml-doctools

echo "🔗 STEP 1.3: Installing XRDP packages..."
apt install -y \
    xrdp \
    xorgxrdp \
    libpipewire-0.3-modules-xrdp \
    pipewire-module-xrdp \
    python3-xkit

echo "🖥️  STEP 1.4: Installing Ubuntu GNOME Desktop..."
apt install -y \
    ubuntu-gnome-desktop \
    gnome-tweaks \
    gnome-shell-extensions


echo "🔧 STEP 1.5: Installing additional packages..."
apt install -y \
    apt-utils \
    dbus-user-session \
    fakeroot \
    kmod \
    locales \
    ssl-cert \
    sudo \
    udev \
    tzdata \
    dbus-x11 \
    zenity \
    snapd \
    qemu-guest-agent \
    mesa-utils \
    vulkan-tools \
    inxi \
    vainfo \
    libva2 \
    mesa-va-drivers \
    vdpauinfo \
    libva-drm2 \
    glmark2 \
    hardinfo \
    htop \
    iotop \
    ncdu \
    tree \
    curl \
    wget \
    git \
    rsync \
    zip \
    unzip \
    p7zip-full \
    nano \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-dev \
    curl \
    wget \
    hplip \
    mpg123 \
    ffmpeg \
    x264 \
    x265


# NOTE: Steam installation is commented out for now
#echo "🎮 STEP 1.6: Installing Steam dependencies..."
# Enable i386 architecture for Steam
dpkg --add-architecture i386
apt update
# Install Steam runtime and 32-bit dependencies
apt install -y libc6-i386 libcurl4:i386 libglib2.0-0:i386 libgtk2.0-0:i386 libgtk-3-0:i386
apt install -y libasound2:i386 libvulkan1:i386 mesa-vulkan-drivers:i386 libgl1:i386 libgl1-mesa-dri:i386
apt install -y libxcursor1:i386 libxi6:i386 libxtst6:i386 libdbus-1-3:i386 libnspr4:i386 libnss3:i386
apt install -y libpulse0:i386 pulseaudio-module-bluetooth:i386 libxinerama1:i386 libgdk-pixbuf-2.0-0:i386 libcairo2:i386 libpango-1.0-0:i386 libatk1.0-0:i386 libfreetype6:i386 libfontconfig1:i386 zlib1g:i386 libpng16-16:i386
apt install -y steam-devices

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
# STEP 3: CREATING CUSTOM SYSTEMD UNITS
# =======================================================================

echo "🔧 STEP 3.1: Creating Xorg Headless service..."
cat > /etc/systemd/system/xorg-headless.service << 'XORG_EOF'
[Unit]
Description=Headless Xorg on VT7
After=systemd-user-sessions.service
Before=gnome-headless@.service

[Service]
User=root
Group=root
Environment=DISPLAY=:0
PermissionsStartOnly=true

#ExecStartPre=/bin/mkdir -p /tmp/.X11-unix
#ExecStartPre=/bin/chown root:root /tmp/.X11-unix
#ExecStartPre=/bin/chmod 1777 /tmp/.X11-unix

ExecStart=/usr/lib/xorg/Xorg :0 vt7 -config /etc/X11/xorg.conf.d/10-headless-amdgpu.conf -noreset -nolisten tcp -ac

Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
XORG_EOF

echo "🔧 STEP 3.2: Creating GNOME Headless service..."
cat > /etc/systemd/system/gnome-headless@.service << 'GNOME_EOF'
[Unit]
Description=GNOME Headless Session (%i)
After=network-online.target xorg-headless.service
Wants=network-online.target
Requires=xorg-headless.service

[Service]
Type=simple
User=%i
Group=%i
PAMName=login
Environment=DISPLAY=:0
Environment=QT_QPA_PLATFORM=xcb
Environment=XDG_SESSION_TYPE=x11
Environment=GDMSESSION=gnome
Environment=GNOME_SHELL_SESSION_MODE=ubuntu
PermissionsStartOnly=true

ExecStartPre=/bin/sh -c 'U=$(id -u %i); install -d -m700 -o %i -g %i /run/user/$U'
ExecStartPre=/bin/sh -lc 'for i in $(seq 1 100); do [ -S /tmp/.X11-unix/X0 ] && xdpyinfo -display :0 >/dev/null 2>&1 && exit 0; sleep 0.2; done; echo "X :0 not ready"; exit 1'
ExecStart=/bin/sh -lc 'U=$(id -u %i); export XDG_RUNTIME_DIR=/run/user/$U; exec dbus-run-session gnome-session'

Restart=on-failure
RestartSec=1
TimeoutStartSec=25

[Install]
WantedBy=multi-user.target
GNOME_EOF

# =======================================================================
# STEP 4: CREATING XORG CONFIGURATION
# =======================================================================

echo "🖥️  STEP 4: Creating Xorg configuration..."
cat > /etc/X11/xorg.conf.d/10-headless-amdgpu.conf << 'XORG_CONF_EOF'
# /etc/X11/xorg.conf.d/10-headless-amdgpu.conf
Section "Monitor"
    Identifier "Monitor0"
    Option "DPMS" "false"
    Option "PreferredMode" "1920x1080"
    # Dynamic modes will be added via xrandr
EndSection

Section "Device"
    Identifier "AMDgpu0"
    Driver "amdgpu"
    Option "AccelMethod" "glamor"
    Option "TearFree" "true"
    Option "DRI" "3"
    Option "DRI3" "Enable"
    Option "DRI3" "1"
    Option "VirtualHeads" "1"
EndSection

Section "Screen"
    Identifier "Screen0"
    Device "AMDgpu0"
    Monitor "Monitor0"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Virtual 1920 1080
        Modes "1920x1080_60.00"
    EndSubSection
EndSection

Section "ServerLayout"
    Identifier "Layout0"
    Screen 0 "Screen0"
EndSection

XORG_CONF_EOF

#sed -i 's|param=xrdp/xorg.conf|param=/etc/X11/xorg.conf.d/10-headless-amdgpu.conf|' /etc/xrdp/sesman.ini

# =======================================================================
# STEP 6: CONFIGURING AND STARTING SERVICES
# =======================================================================

echo "⚙️  STEP 6.1: Reloading systemd..."
systemctl daemon-reload

# echo "▶️  STEP 6.2: Enabling and starting services..."
systemctl enable xorg-headless.service
# systemctl enable xrdp.service
# systemctl enable xrdp-sesman.service

# echo "▶️  STEP 6.3: Starting services..."
 systemctl start xorg-headless.service
# systemctl start xrdp.service
# systemctl start xrdp-sesman.service

 echo "▶️  STEP 6.4: Enabling GNOME for user sip..."
 systemctl enable gnome-headless@sip.service
 systemctl start gnome-headless@sip.service


# =======================================================================
# ROCm PACKAGES INSTALLATION - ADDED FOR GPU SUPPORT
# =======================================================================
echo "🔧 STEP 1.8: Installing ROCm packages for GPU support..."
apt install -y rocm-smi rocminfo libamdhip64-5 mesa-vulkan-drivers


# =======================================================================
# AMD GPU MONITORING - AMDGPU_TOP INSTALLATION
# =======================================================================
echo "🔧 STEP 1.9: Installing AMD GPU monitoring tools..."

# Update package list first
apt update

# Install required packages
apt install -y cargo libdrm-dev libdrm-amdgpu1 curl wget build-essential

# Verify essential tools
for tool in curl wget; do
    if ! command -v $tool >/dev/null 2>&1; then
        echo "ERROR: $tool not found"
        exit 1
    fi
done

if ! command -v cargo >/dev/null 2>&1; then
    echo "Installing cargo..."
    apt install -y cargo
fi

echo "✓ All tools ready"

# Setup Rust environment
export PATH="$HOME/.cargo/bin:/usr/local/bin:$PATH"

# Smart Rust installation
if command -v cargo >/dev/null 2>&1; then
    echo "Cargo found:"
    cargo --version

    # Try to install amdgpu_top with current Rust
    echo "Trying to install amdgpu_top..."
    if cargo install amdgpu_top --locked 2>/dev/null; then
        echo "✓ Success with system Rust!"
    else
        echo "System Rust failed, trying rustup..."

        # Install rustup if needed
        if ! command -v rustup >/dev/null 2>&1; then
            echo "Installing rustup..."
            curl -sSf https://sh.rustup.rs | sh -s -- --default-toolchain nightly -y

            # Source environment
            if [ -f "$HOME/.cargo/env" ]; then
                source "$HOME/.cargo/env"
                export PATH="$HOME/.cargo/bin:$PATH"
            fi
        fi

        # Try with rustup
        if command -v rustup >/dev/null 2>&1; then
            rustup toolchain install nightly --profile minimal 2>/dev/null || true
            rustup default nightly 2>/dev/null || true
        fi

        # Final attempt
        if ! cargo install amdgpu_top --locked; then
            echo "ERROR: All installation methods failed"
            exit 1
        fi
    fi
else
    echo "ERROR: No Rust installation found"
    exit 1
fi

# Copy binaries
if [ -f "$HOME/.cargo/bin/amdgpu_top" ]; then
    cp "$HOME/.cargo/bin/amdgpu_top" /usr/local/bin/
    chmod +x /usr/local/bin/amdgpu_top
    echo "✓ amdgpu_top installed"
else
    echo "ERROR: amdgpu_top not found"
    exit 1
fi

echo ""
echo "📋 AMD GPU monitoring tools installed successfully!"
echo "🔍 Usage: amdgpu_top"
echo "✅ Setup complete!"


# =======================================================================
# NOMACHINE REMOTE DESKTOP INSTALLATION
# =======================================================================
echo "🔧 STEP 1.8.2: Installing NoMachine remote desktop server..."

# Advanced NoMachine installer (downloads latest .deb for current architecture)
# Resilient to redirects/cookies and provides detailed logs.

ARCH="$(dpkg --print-architecture)"    # amd64 / arm64 etc.
UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Safari/537.36'
ACCEPT_LANG='en;q=0.9,ru;q=0.8'
TMPDIR="$(mktemp -d -t nomx-XXXXXX)"
CJ="$TMPDIR/cookies.txt"
PRIMARY_URL="https://www.nomachine.com/download/download&id=1"
ALT_URL="https://download.nomachine.com/download/?id=1&platform=linux"
TS="$(date +%s)" # cache-bust

# Ensure curl/ca-certificates are available
if ! command -v curl >/dev/null 2>&1; then
  apt-get update -y >/dev/null 2>&1
  apt-get install -y curl ca-certificates >/dev/null 2>&1
fi

log() { echo "$@"; }

fetch_html () {
  local url="$1"
  log "   -> GET $url"
  # Separate cookie jar for each run; limit redirects; set headers
  curl -fsSL \
    --max-redirs 20 \
    -A "$UA" \
    -H "Accept-Language: $ACCEPT_LANG" \
    -e "https://www.nomachine.com/download" \
    -c "$CJ" -b "$CJ" \
    -m 30 \
    "$url"
}

parse_link_id() {
  # Search specifically for <a id="link_download" href="...deb">
  sed -n 's/.*id="link_download" href="\([^"]*\.deb\)".*/\1/p' | head -n1
}

parse_link_arch() {
  # Fallback: any link to nomachine_*_ARCH.deb
  sed -n "s|.*href=\"\\([^\"]*nomachine_[^\"]*_${ARCH}\\.deb\\)\".*|\\1|p" | head -n1
}

follow_meta_refresh() {
  sed -n 's/.*http-equiv="refresh".*url=\([^"]*\)".*/\1/p' | head -n1
}

log " - Fetching latest NoMachine .deb link..."
DL_URL=""

# 1) Primary URL with cache-bust
HTML="$(fetch_html "${PRIMARY_URL}&_ts=${TS}" 2>/dev/null || true)"
if [[ -z "${HTML:-}" ]]; then
  log "   ! Primary returned empty. Trying ALT..."
else
  DL_URL="$(printf '%s\n' "$HTML" | parse_link_id 2>/dev/null || true)"
  [[ -n "$DL_URL" ]] && log "   -> Parsed via id=link_download (primary)"
fi

# 2) If not found - try meta refresh on primary
if [[ -z "$DL_URL" && -n "${HTML:-}" ]]; then
  META_URL="$(printf '%s\n' "$HTML" | follow_meta_refresh 2>/dev/null || true)"
  if [[ -n "$META_URL" ]]; then
    log "   -> Following meta refresh (primary): $META_URL"
    HTML2="$(fetch_html "${META_URL}&_ts=${TS}" 2>/dev/null || true)"
    if [[ -n "${HTML2:-}" ]]; then
      DL_URL="$(printf '%s\n' "$HTML2" | parse_link_id 2>/dev/null || true)"
      [[ -n "$DL_URL" ]] && log "   -> Parsed via id=link_download (meta)"
      [[ -z "$DL_URL" ]] && DL_URL="$(printf '%s\n' "$HTML2" | parse_link_arch 2>/dev/null || true)"
      [[ -n "$DL_URL" ]] && log "   -> Parsed via *_${ARCH}.deb (meta)"
    fi
  fi
fi

# 3) If still empty - try ALT URL
if [[ -z "$DL_URL" ]]; then
  HTML_ALT="$(fetch_html "${ALT_URL}&_ts=${TS}" 2>/dev/null || true)"
  if [[ -n "${HTML_ALT:-}" ]]; then
    DL_URL="$(printf '%s\n' "$HTML_ALT" | parse_link_id 2>/dev/null || true)"
    [[ -n "$DL_URL" ]] && log "   -> Parsed via id=link_download (alt)"
    if [[ -z "$DL_URL" ]]; then
      log "   ! Fallback on ALT: search for *_${ARCH}.deb"
      DL_URL="$(printf '%s\n' "$HTML_ALT" | parse_link_arch 2>/dev/null || true)"
    fi
  fi
fi

# 4) Final validation
if [[ -z "$DL_URL" ]]; then
  log " ! ERROR: could not parse a .deb URL for arch: ${ARCH}"
  log "   Tip: check network connectivity and site availability"
  rm -rf "$TMPDIR"
  exit 1
fi

# 5) If id-link gave wrong arch - filter it
if ! [[ "$DL_URL" =~ _${ARCH}\.deb$ ]]; then
  log "   ! Parsed URL arch mismatch; searching for matching *_${ARCH}.deb..."
  CANDIDATE="$(printf '%s\n' "${HTML:-}${HTML2:-}${HTML_ALT:-}" | parse_link_arch 2>/dev/null || true)"
  if [[ -n "$CANDIDATE" ]]; then
    DL_URL="$CANDIDATE"
    log "   -> Using: $DL_URL"
  fi
fi

log " - Found: $DL_URL"
PKG="$TMPDIR/$(basename "$DL_URL")"

log " - Downloading package..."
curl -fSL --max-redirs 20 -A "$UA" -H "Accept-Language: $ACCEPT_LANG" -c "$CJ" -b "$CJ" -m 180 -o "$PKG" "$DL_URL"

# 6) Installation
if ! dpkg -i "$PKG"; then
  log " - dpkg failed, resolving dependencies..."
  apt-get update -y >/dev/null 2>&1
  apt-get -f install -y >/dev/null 2>&1
  # Retry if needed
  dpkg -i "$PKG" 2>/dev/null || true
fi

log " - Cleaning up..."
rm -rf "$TMPDIR"

log " - NoMachine installed successfully."
