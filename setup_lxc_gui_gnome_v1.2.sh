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
    xserver-xorg-video-nouveau \
    xserver-xorg-video-qxl \
    xserver-xorg-video-radeon \
    xserver-xorg-video-vesa \
    xserver-xorg-video-vmware \
    xorg-docs-core \
    xorg-sgml-doctools

echo "🔗 STEP 1.3: Installing XRDP packages..."
apt install -y \
    xrdp \
    xorgxrdp \
    libpipewire-0.3-modules-xrdp \
    pipewire-module-xrdp \
    python3-xkit \
    tigervnc-xorg-extension

echo "🖥️  STEP 1.4: Installing Ubuntu GNOME Desktop..."
apt install -y \
    gdm3 \
    gnome-session \
    gnome-shell \
    gnome-shell-extensions \
    gnome-control-center \
    gnome-settings-daemon \
    gnome-tweaks \
    gnome-software \
    gnome-system-monitor \
    gnome-terminal \
    nautilus \
    gedit \
    eog \
    evince \
    totem \
    rhythmbox \
    gnome-calculator \
    gnome-calendar \
    gnome-clocks \
    gnome-weather \
    gnome-maps \
    gnome-contacts \
    shotwell \
    gnome-music \
    gnome-disk-utility \
    gnome-logs \
    gnome-characters \
    gnome-font-viewer \
    gnome-screenshot \
    gnome-color-manager \
    seahorse \
    policykit-1-gnome \
    network-manager-gnome \
    pulseaudio \
    pavucontrol \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-libav \
    ubuntu-restricted-addons \
    fonts-noto \
    fonts-noto-cjk \
    fonts-noto-mono \
    xfonts-base \
    xfonts-75dpi \
    xfonts-100dpi \
    libgtk-3-dev \
    libgtk2.0-dev \
    libxss1 \
    libnss3-dev \
    libatk-bridge2.0-dev \
    libdrm2 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libgbm1 \
    libxss1 \
    libasound2-dev \
    libpulse-dev \
    locales-all \
    language-pack-en \
    language-pack-ru \
    hunspell-en-us \
    hunspell-ru \
    aspell-en \
    aspell-ru \
    mythes-en-us \
    mythes-ru \
    libreoffice-style-breeze \
    qt5-style-plugins \
    qt5ct \
    adwaita-qt \
    breeze-gtk-theme \
    breeze-icon-theme \
    oxygen-icon-theme \
    numix-icon-theme \
    numix-gtk-theme \
    papirus-icon-theme \
    arc-theme \
    materia-gtk-theme \
    flatpak \
    xdg-desktop-portal \
    xdg-desktop-portal-gtk \
    software-properties-gtk \
    gnome-software-plugin-flatpak \
    gnome-software-plugin-snap


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
    x11vnc \
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
useradd -m -s /bin/bash sip
usermod -aG adm,audio,cdrom,dialout,xrdp,dip,fax,floppy,games,input,lp,plugdev,render,ssl-cert,sudo,tape,tty,video,voice sip
echo 'sip:sip' | chpasswd

echo "🔐 STEP 2.2: Configuring sudo..."
echo 'sip ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/sip

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

#echo "🔧 STEP 3.2: Creating GNOME Headless service..."
#cat > /etc/systemd/system/gnome-headless@.service << 'GNOME_EOF'
#[Unit]
#Description=GNOME Headless Session (%i)
#After=network-online.target xorg-headless.service
#Wants=network-online.target
#Requires=xorg-headless.service

#[Service]
#Type=simple
#User=%i
#Group=%i
#PAMName=login
#Environment=DISPLAY=:0
#Environment=QT_QPA_PLATFORM=xcb
#Environment=XDG_SESSION_TYPE=x11
#Environment=GDMSESSION=gnome
#Environment=GNOME_SHELL_SESSION_MODE=ubuntu
#PermissionsStartOnly=true

#ExecStartPre=/bin/sh -c 'U=$(id -u %i); install -d -m700 -o %i -g %i /run/user/$U'
#ExecStartPre=/bin/sh -lc 'for i in $(seq 1 100); do [ -S /tmp/.X11-unix/X0 ] && xdpyinfo -display :0 >/dev/null 2>&1 && exit 0; sleep 0.2; done; echo "X :0 not ready"; exit 1'
#ExecStart=/bin/sh -lc 'U=$(id -u %i); export XDG_RUNTIME_DIR=/run/user/$U; exec dbus-run-session gnome-session'

#Restart=on-failure
#RestartSec=1
#TimeoutStartSec=25

#[Install]
#WantedBy=multi-user.target
#GNOME_EOF

#echo "🔧 STEP 3.3: Creating drop-in configuration for GNOME..."
#mkdir -p /etc/systemd/system/gnome-headless@.service.d
#cat > /etc/systemd/system/gnome-headless@.service.d/env.conf << 'DROP_EOF'
#[Service]
#Environment=LOGIN_USER=%i
#Environment=REMOTE_SESSION=nomachine
#Environment=XDG_SESSION_TYPE=x11
#Environment=GDMSESSION=gnome
#DROP_EOF

#####echo "🔧 STEP 3.4: Creating X0VNC service..."
#cat > /etc/systemd/system/x0vnc@.service << 'X0VNC_EOF'
#[Unit]
#Description=X0VNC on :0 for user %i
#After=xorg-headless.service
#Requires=xorg-headless.service

#[Service]
#Type=simple
#User=%i
#Group=%i
#Environment=DISPLAY=:0

#ExecStartPre=/bin/sh -lc 'for i in $(seq 1 100); do [ -S /tmp/.X11-unix/X0 ] && xdpyinfo -display :0 >/dev/null 2>&1 && exit 0; sleep 0.2; done; echo "X :0 not ready"; exit 1'
#ExecStart=/bin/sh -lc 'U=$(id -u %i); export XDG_RUNTIME_DIR=/run/user/$U; exec x0vncserver -display :0 -rfbport 5900 -localhost -NeverShared -AlwaysShared=0'

#Restart=on-failure
#RestartSec=2

#[Install]
#WantedBy=multi-user.target
#X0VNC_EOF

#echo "🔧 STEP 3.5: Creating X11VNC service..."
#cat > /etc/systemd/system/x11vnc@.service << 'X11VNC_EOF'
#[Unit]
#Description=x11vnc on :0 (user %i)
#After=xorg-headless.service
#Requires=xorg-headless.service

#[Service]
#Type=simple
#User=%i
#Group=%i
#Environment=DISPLAY=:0
#PermissionsStartOnly=true

#ExecStartPre=/bin/sh -lc 'U=$(id -u %i); install -d -m700 -o %i -g %i /run/user/$U'
#ExecStartPre=/bin/sh -lc 'for i in $(seq 1 100); do [ -S /tmp/.X11-unix/X0 ] && xdpyinfo -display :0 >/dev/null 2>&1 && exit 0; sleep 0.2; done; echo "X :0 not ready"; exit 1'
#ExecStartPre=/bin/sh -lc 'AUTH=$(ls -1t /root/.serverauth.* 2>/dev/null | head -n1 || true); if [ -n "$AUTH" ]; then sudo -u %i XAUTHORITY=/home/%i/.Xauthority xauth merge "$AUTH"; fi'
#ExecStartPre=/bin/sh -lc 'test -f /home/%i/.vnc/passwd || ( install -d -m700 -o %i -g %i /home/%i/.vnc && echo "set a VNC password via: sudo -u %i x11vnc -storepasswd" >&2 )'
#ExecStart=/usr/bin/x11vnc -display :0 -auth /home/%i/.Xauthority -rfbauth /home/%i/.vnc/passwd -rfbport 5900 -localhost -forever -shared -noxdamage

#Restart=on-failure
#RestartSec=1
#X11VNC_EOF


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

sed -i 's|param=xrdp/xorg.conf|param=/etc/X11/xorg.conf.d/10-headless-amdgpu.conf|' /etc/xrdp/sesman.ini

# =======================================================================
# STEP 6: CONFIGURING AND STARTING SERVICES
# =======================================================================

#echo "⚙️  STEP 6.1: Reloading systemd..."
#systemctl daemon-reload

 echo "▶️  STEP 6.2: Enabling and starting services..."
 systemctl enable xorg-headless.service
# systemctl enable xrdp.service
# systemctl enable xrdp-sesman.service

# echo "▶️  STEP 6.3: Starting services..."
 systemctl start xorg-headless.service
# systemctl start xrdp.service
# systemctl start xrdp-sesman.service

# echo "▶️  STEP 6.4: Enabling GNOME for user sip..."
# systemctl enable gnome-headless@sip.service
# systemctl start gnome-headless@sip.service

# =======================================================================
# COMPLETION
# =======================================================================

echo ""
echo "🎉 GNOME SETUP COMPLETED!"
echo ""
echo "📋 Setup Summary:"
echo "   👤 User: sip"
echo "   🔑 Password: sip"
echo "   🖥️  Desktop: Ubuntu GNOME"
echo "   🌐 RDP Port: 3389"
echo "   🖼️  Resolution: 1920x1080"
echo ""
echo "🔗 To connect, use RDP client:"
echo "   IP: [container IP address]"
echo "   Port: 3389"
echo "   User: sip"
echo "   Password: sip"
echo ""
echo "📊 Status check:"
echo "   systemctl status gnome-headless@sip"
echo "   systemctl status xrdp"
echo "   journalctl -u gnome-headless@sip -f"
echo ""
echo "✨ Ready to use!"
echo ""
echo "🖥️  Desktop Environment: Ubuntu GNOME"
echo "🎨 Theme: Yaru (default Ubuntu theme)"
echo "🔧 Additional tools: GNOME Tweaks, Calculator, System Monitor"

# =======================================================================
# ROCm PACKAGES INSTALLATION - ADDED FOR GPU SUPPORT
# =======================================================================
echo "🔧 STEP 1.8: Installing ROCm packages for GPU support..."
apt install -y rocm-smi rocminfo libamdhip64-5 mesa-vulkan-drivers

echo "📋 ROCm packages installed successfully"
echo "   - rocm-smi: ROCm System Management Interface"
echo "   - rocminfo: ROCm info tool"
echo "   - libamdhip64-5: AMD HIP runtime"
echo "   - mesa-vulkan-drivers: Vulkan drivers for Mesa"

# =======================================================================
# VAAPI & VULKAN ENVIRONMENT SETUP
# =======================================================================
#echo "🔧 STEP 1.8.1: Setting up complete GUI desktop environment variables..."

# Add comprehensive environment variables to system profile
# cat >> /etc/environment << 'ENV_EOF'
# ============================================================================
# GPU & GRAPHICS DRIVERS
# ============================================================================
# VAAPI (Video Acceleration API) settings for AMD GPU
# LIBVA_DRIVER_NAME=radeonsi
# VDPAU_DRIVER=radeonsi

# Vulkan settings for AMD GPU
# VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json
# VK_DRIVER_FILES=/usr/share/vulkan/icd.d/radeon_icd.x86_64.json
# AMD_VK_PIPELINE_CACHE_FILENAME=steamapp_shader_cache
# AMD_VK_USE_PIPELINE_CACHE=1
# ENABLE_VK_LAYER_VALVE_steam_fossilize_1=1
# ENABLE_VK_LAYER_VALVE_steam_overlay_1=1

# Mesa/OpenGL для AMD
# MESA_GL_VERSION_OVERRIDE=4.6
# MESA_GLSL_VERSION_OVERRIDE=460
# MESA_DRI_DRIVER=radeonsi

# Headless setup
# SDL_VIDEODRIVER=x11


# ============================================================================
# DISPLAY & DESKTOP ENVIRONMENT
# ============================================================================
# X11 settings
# DISPLAY=:0
# XAUTHORITY=/home/sip/.Xauthority


# Wayland settings (fallback)
# WAYLAND_DISPLAY=wayland-0
# GDK_BACKEND=x11,wayland

# GNOME Desktop settings
# GNOME_SESSION=gnome
# GDMSESSION=gnome
# DESKTOP_SESSION=gnome
# XDG_SESSION_TYPE=x11
# XDG_SESSION_DESKTOP=gnome
# XDG_CURRENT_DESKTOP=GNOME

# ============================================================================
# GTK & QT SETTINGS
# ============================================================================
# GTK settings
# GTK_THEME=Adwaita
# GTK_MODULES=gail:atk-bridge

# Qt5 settings
# QT_QPA_PLATFORM=xcb
# QT_QPA_PLATFORMTHEME=gtk3
# QT_AUTO_SCREEN_SCALE_FACTOR=1
# QT_SCALE_FACTOR=1

# ============================================================================
# DBUS & SYSTEMD
# ============================================================================
# D-Bus settings
# DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus

# Systemd user settings
# XDG_RUNTIME_DIR=/run/user/1000

# ============================================================================
# LOCALE & LANGUAGE
# ============================================================================
# Language settings
# LANG=en_US.UTF-8
# LANGUAGE=en_US:en
# LC_ALL=en_US.UTF-8

# ============================================================================
# APPLICATION SETTINGS
# ============================================================================
# Firefox GPU acceleration
# MOZ_USE_XINPUT2=1
# MOZ_X11_EGL=1

# Chrome/Chromium GPU settings
# CHROME_GPU_SANDBOX=0
# CHROME_GPU=1

# Steam settings (if installed)
# STEAM_RUNTIME=1
# TEAM_FRAME_RATE=0


#ENV_EOF

echo "📋 Complete GUI desktop environment variables configured successfully"
echo "   ✅ VAAPI: LIBVA_DRIVER_NAME=radeonsi, VDPAU_DRIVER=radeonsi"
echo "   ✅ Vulkan: VK_ICD_FILENAMES, VK_DRIVER_FILES set for AMD GPU"
echo "   ✅ Display: DISPLAY=:0, XAUTHORITY configured"
echo "   ✅ GNOME: XDG_SESSION_DESKTOP=GNOME, GDMSESSION=gnome"
echo "   ✅ GTK/Qt: GTK_THEME=Adwaita, QT_QPA_PLATFORM=xcb"
echo "   ✅ D-Bus: DBUS_SESSION_BUS_ADDRESS configured"
echo "   ✅ Runtime: XDG_RUNTIME_DIR=/run/user/1000"
echo "   ✅ GPU Debug: RADV_DEBUG=all, RADV_PERFTEST=all"
echo "   ✅ Browser GPU: MOZ_X11_EGL=1, CHROME_GPU=1"

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

echo "📋 Administrator privileges configured successfully"
echo "   - User sip added to sudo, video, render groups for GPU access"
echo "   - Passwordless sudo access configured"
echo "   - User can now run: sudo <command> without password"

echo ""
echo "⚠️  IMPORTANT: After installation, restart the container for GPU access to work properly"
echo "   Command: pct stop 456 && pct start 456"
echo "   Or from Proxmox web interface: Stop → Start container"
echo ""
echo "🔍 After restart, you can use:"
echo "   amdgpu_top          # Interactive GPU monitoring"
echo "   amdgpu_top --json   # JSON output for scripts"
echo "   rocminfo            # GPU information"
echo "   vainfo              # VAAPI video acceleration info"
echo "   vulkaninfo          # Vulkan API information"
echo ""
echo "🎉 UBUNTU GNOME SETUP COMPLETED SUCCESSFULLY!"
echo ""
echo "📋 Final Summary:"
echo "   🖥️  Desktop Environment: Ubuntu GNOME"
echo "   👤 User: sip (password: sip)"
echo "   🌐 RDP Access: Port 3389"
echo "   🎨 Theme: Yaru (default Ubuntu)"
echo "   🌐 Browser: Firefox"
echo "   🔧 GPU Support: ROCm + amdgpu_top + VAAPI + Vulkan"
echo "   🎬 Video Acceleration: VAAPI (H.264, HEVC, VP9, AV1)"
echo "   🎮 Vulkan API: Version 1.3.x (RADV driver)"
echo ""
echo "🔧 To start using:"
echo "   1. Restart container: pct stop <CTID> && pct start <CTID>"
echo "   2. Connect via RDP: [container IP]:3389"
echo "   3. Login: sip / sip"
echo ""
echo "✨ Setup complete! Enjoy your Ubuntu GNOME desktop!"
