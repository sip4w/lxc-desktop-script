# =======================================================================
# SETUP LXC GUI SCRIPT - VERSION 1.1 (WITH ROCM GPU SUPPORT VERSION 1.0 (WITH ROCM GPU SUPPORT) RUST FIXES)
# Status: Working GUI with ROCM packages for enhanced GPU support
# =======================================================================
# =======================================================================
#!/bin/bash

# =======================================================================
# SCRIPT FOR SETTING UP GUI IN EXISTING LXC CONTAINER
# Based on README_GUI_LXC_Deployment.md
# =======================================================================

set -e  # Stop script on error

echo "рџљЂ STARTING GUI SETUP IN EXISTING LXC CONTAINER"

# =======================================================================
# STEP 1: UPDATING SYSTEM AND INSTALLING PACKAGES
# =======================================================================

echo "рџ“¦ STEP 1.1: Updating system..."
apt update && apt upgrade -y

echo "рџ–ҐпёЏ  STEP 1.2: Installing base Xorg packages..."
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

echo "рџ”— STEP 1.3: Installing XRDP packages..."
apt install -y \
    xrdp \
    xorgxrdp \
    libpipewire-0.3-modules-xrdp \
    pipewire-module-xrdp \
    python3-xkit \
    tigervnc-xorg-extension

echo "рџ–ҐпёЏ  STEP 1.4: Installing KDE Plasma Desktop..."
apt install -y \
    kde-plasma-desktop \
    sddm \
    plasma-desktop \
    plasma-framework \
    plasma-workspace \
    plasma-nm \
    plasma-pa \
    plasma-firewall \
    plasma-discover \
    plasma-systemmonitor \
    plasma-thunderbolt \
    plasma-vault \
    plasma-widgets-addons \
    plasma-runners-addons \
    plasma-dataengines-addons \
    plasma-browser-integration \
    kde-config-sddm \
    polkit-kde-agent-1 \
    kded5 \
    kde-cli-tools \
    kde-style-breeze \
    breeze \
    breeze-icon-theme \
    breeze-cursor-theme \
    libkf5plasma5 \
    libkf5plasmaquick5 \
    libplasma-geolocation-interface5 \
    libtaskmanager6 \
    libnotificationmanager1 \
    libcolorcorrect5 \
    libkworkspace5-5 \
    qml-module-org-kde-activities \
    qml-module-org-kde-bluezqt \
    qml-module-org-kde-draganddrop \
    qml-module-org-kde-kcm \
    qml-module-org-kde-kcmutils \
    qml-module-org-kde-kconfig \
    qml-module-org-kde-kcoreaddons \
    qml-module-org-kde-kholidays \
    qml-module-org-kde-kio \
    qml-module-org-kde-kirigami2 \
    qml-module-org-kde-kitemmodels \
    qml-module-org-kde-kquickcontrolsaddons \
    qml-module-org-kde-kquickcontrols \
    qml-module-org-kde-newstuff \
    qml-module-org-kde-pipewire \
    qml-module-org-kde-prison \
    qml-module-org-kde-purpose \
    qml-module-org-kde-qqc2desktopstyle \
    qml-module-org-kde-quickcharts \
    qml-module-org-kde-runnermodel \
    qml-module-org-kde-solid \
    qml-module-org-kde-sonnet \
    qml-module-org-kde-syntaxhighlighting \
    qml-module-org-kde-userfeedback

echo "рџ”§ STEP 1.5: Installing additional packages..."
apt install -y \
    x11vnc \
    dbus-x11 \
    zenity \
    curl \
    wget \
    git \
    vim \
    htop \
    sudo

#shit
#echo "рџЋ® STEP 1.6: Installing Steam dependencies..."
# Enable i386 architecture for Steam
#dpkg --add-architecture i386
#apt update

# Install Steam runtime and 32-bit dependencies
#apt install -y libc6-i386 libcurl4:i386 libglib2.0-0:i386 libgtk2.0-0:i386 libgtk-3-0:i386
#apt install -y libasound2:i386 libvulkan1:i386 mesa-vulkan-drivers:i386 libgl1:i386
#apt install -y libgl1-mesa-dri:i386 libxcursor1:i386 libxi6:i386 libxtst6:i386
#apt install -y libdbus-1-3:i386 libnspr4:i386 libnss3:i386 libsasl2-modules:i386



# =======================================================================
# STEP 2: USER CONFIGURATION
# =======================================================================

echo "рџ‘¤ STEP 2.1: Creating user..."
useradd -m -s /bin/bash sip
usermod -aG sudo,video,render sip
echo 'sip:sip' | chpasswd

echo "рџ”ђ STEP 2.2: Configuring sudo..."
echo 'sip ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/sip

# =======================================================================
# STEP 3: CREATING CUSTOM SYSTEMD UNITS
# =======================================================================

echo "рџ”§ STEP 3.1: Creating Xorg Headless service..."
cat > /etc/systemd/system/xorg-headless.service << 'XORG_EOF'
[Unit]
Description=Headless Xorg on VT11
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

ExecStart=/usr/lib/xorg/Xorg :0 vt11 -config /etc/X11/xorg.conf.d/10-headless-amdgpu.conf -noreset -nolisten tcp -ac

Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
XORG_EOF

echo "рџ”§ STEP 3.2: Creating Plasma Headless service..."
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
Environment=DISPLAY=:0
Environment=QT_QPA_PLATFORM=xcb
PermissionsStartOnly=true

ExecStartPre=/bin/sh -c 'U=$(id -u %i); install -d -m700 -o %i -g %i /run/user/$U'
ExecStartPre=/bin/sh -lc 'for i in $(seq 1 100); do [ -S /tmp/.X11-unix/X0 ] && xdpyinfo -display :0 >/dev/null 2>&1 && exit 0; sleep 0.2; done; echo "X :0 not ready"; exit 1'
ExecStart=/bin/sh -lc 'U=$(id -u %i); export XDG_RUNTIME_DIR=/run/user/$U; exec dbus-run-session startplasma-x11'

Restart=on-failure
RestartSec=1
TimeoutStartSec=25

[Install]
WantedBy=multi-user.target
PLASMA_EOF

echo "рџ”§ STEP 3.3: Creating drop-in configuration for Plasma..."
mkdir -p /etc/systemd/system/plasma-headless@.service.d
cat > /etc/systemd/system/plasma-headless@.service.d/env.conf << 'DROP_EOF'
[Service]
Environment=LOGIN_USER=%i
Environment=REMOTE_SESSION=nomachine
Environment=XDG_SESSION_TYPE=x11
DROP_EOF

echo "рџ”§ STEP 3.4: Creating X0VNC service..."
cat > /etc/systemd/system/x0vnc@.service << 'X0VNC_EOF'
[Unit]
Description=X0VNC on :0 for user %i
After=xorg-headless.service
Requires=xorg-headless.service

[Service]
Type=simple
User=%i
Group=%i
Environment=DISPLAY=:0

ExecStartPre=/bin/sh -lc 'for i in $(seq 1 100); do [ -S /tmp/.X11-unix/X0 ] && xdpyinfo -display :0 >/dev/null 2>&1 && exit 0; sleep 0.2; done; echo "X :0 not ready"; exit 1'
ExecStart=/bin/sh -lc 'U=$(id -u %i); export XDG_RUNTIME_DIR=/run/user/$U; exec x0vncserver -display :0 -rfbport 5900 -localhost -NeverShared -AlwaysShared=0'

Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
X0VNC_EOF

echo "рџ”§ STEP 3.5: Creating X11VNC service..."
cat > /etc/systemd/system/x11vnc@.service << 'X11VNC_EOF'
[Unit]
Description=x11vnc on :0 (user %i)
After=xorg-headless.service
Requires=xorg-headless.service

[Service]
Type=simple
User=%i
Group=%i
Environment=DISPLAY=:0
PermissionsStartOnly=true

ExecStartPre=/bin/sh -lc 'U=$(id -u %i); install -d -m700 -o %i -g %i /run/user/$U'
ExecStartPre=/bin/sh -lc 'for i in $(seq 1 100); do [ -S /tmp/.X11-unix/X0 ] && xdpyinfo -display :0 >/dev/null 2>&1 && exit 0; sleep 0.2; done; echo "X :0 not ready"; exit 1'
ExecStartPre=/bin/sh -lc 'AUTH=$(ls -1t /root/.serverauth.* 2>/dev/null | head -n1 || true); if [ -n "$AUTH" ]; then sudo -u %i XAUTHORITY=/home/%i/.Xauthority xauth merge "$AUTH"; fi'
ExecStartPre=/bin/sh -lc 'test -f /home/%i/.vnc/passwd || ( install -d -m700 -o %i -g %i /home/%i/.vnc && echo "set a VNC password via: sudo -u %i x11vnc -storepasswd" >&2 )'
ExecStart=/usr/bin/x11vnc -display :0 -auth /home/%i/.Xauthority -rfbauth /home/%i/.vnc/passwd -rfbport 5900 -localhost -forever -shared -noxdamage

Restart=on-failure
RestartSec=1
X11VNC_EOF

echo "рџ”§ STEP 3.6: Creating V2RayA service..."
cat > /etc/systemd/system/v2raya.service << 'V2RAYA_EOF'
[Unit]
Description=A web GUI client of Project V which supports VMess, VLESS, SS, SSR, Trojan, Tuic and Juicity protocols
Documentation=https://v2raya.org
After=network.target nss-lookup.target iptables.service ip6tables.service nftables.service
Wants=network.target

[Service]
Environment="V2RAYA_CONFIG=/usr/local/etc/v2raya"
Environment="V2RAYA_LOG_FILE=/tmp/v2raya.log"
Environment="V2RAYA_ADDRESS=127.0.0.1:2017"
Type=simple
User=root
LimitNPROC=500
LimitNOFILE=1000000
ExecStart=/usr/local/bin/v2raya
Restart=on-failure

[Install]
WantedBy=multi-user.target
V2RAYA_EOF

# =======================================================================
# STEP 4: CREATING XORG CONFIGURATION
# =======================================================================

echo "пїЅпїЅпёЏ  STEP 4: Creating Xorg configuration..."
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
# STEP 5: CREATING CUSTOM SCRIPTS
# =======================================================================


# =======================================================================
# STEP 6: CONFIGURING AND STARTING SERVICES
# =======================================================================

echo "вљ™пёЏ  STEP 6.1: Reloading systemd..."
systemctl daemon-reload

echo "в–¶пёЏ  STEP 6.2: Enabling and starting services..."
systemctl enable xorg-headless.service
systemctl enable xrdp.service
systemctl enable xrdp-sesman.service
systemctl enable v2raya.service

echo "в–¶пёЏ  STEP 6.3: Starting services..."
systemctl start xorg-headless.service
systemctl start xrdp.service
systemctl start xrdp-sesman.service
systemctl start v2raya.service

echo "в–¶пёЏ  STEP 6.4: Enabling Plasma for user sip..."
systemctl enable plasma-headless@sip.service
systemctl start plasma-headless@sip.service

# =======================================================================
# COMPLETION
# =======================================================================

echo ""
echo "рџЋ‰ GUI SETUP COMPLETED!"
echo ""
echo "рџ“‹ Setup Summary:"
echo "   рџ‘¤ User: sip"
echo "   рџ”‘ Password: sip"
echo "   рџЊђ RDP Port: 3389"
echo "   рџ–јпёЏ  Resolution: 1920x1080"
echo ""
echo "рџ”— To connect, use RDP client:"
echo "   IP: [container IP address]"
echo "   Port: 3389"
echo "   User: sip"
echo "   Password: sip"
echo ""
echo "рџ“Љ Status check:"
echo "   systemctl status plasma-headless@sip"
echo "   systemctl status xrdp"
echo "   journalctl -u plasma-headless@sip -f"
echo ""
echo "вњЁ Ready to use!"
# =======================================================================
# ROLLBACK TO VERSION 0.7 - WORKING STATE
# Date: Sat Aug 30 13:22:18 UTC 2025
# Status: Stable GUI with RDP working
# =======================================================================
# =======================================================================
# ROCM PACKAGES INSTALLATION - ADDED FOR GPU SUPPORT
# =======================================================================
echo "рџ”§ STEP 1.8: Installing ROCM packages for GPU support..."
apt install -y rocm-smi rocminfo libamdhip64-5 mesa-vulkan-drivers

echo "рџ“‹ ROCM packages installed successfully"
echo "   - rocm-smi: ROCm System Management Interface"
echo "   - rocminfo: ROCm info tool"
echo "   - libamdhip64-5: AMD HIP runtime"
echo "   - mesa-vulkan-drivers: Vulkan drivers for Mesa"
# =======================================================================
# AMD GPU MONITORING - AMDGPU_TOP INSTALLATION
# =======================================================================
echo "рџ”§ STEP 1.9: Installing AMD GPU monitoring tools..."

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

echo "вњ“ All tools ready"

# Setup Rust environment
export PATH="$HOME/.cargo/bin:/usr/local/bin:$PATH"

# Smart Rust installation
if command -v cargo >/dev/null 2>&1; then
    echo "Cargo found:"
    cargo --version
    
    # Try to install amdgpu_top with current Rust
    echo "Trying to install amdgpu_top..."
    if cargo install amdgpu_top --locked 2>/dev/null; then
        echo "вњ“ Success with system Rust!"
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
    echo "вњ“ amdgpu_top installed"
else
    echo "ERROR: amdgpu_top not found"
    exit 1
fi

echo ""
echo "рџ“‹ AMD GPU monitoring tools installed successfully!"
echo "рџ”Ќ Usage: amdgpu_top"
echo "вњ… Setup complete!"
# =======================================================================
# =======================================================================
# NETWORK MANAGER LXC FIXES & BROWSER INSTALLATION
# =======================================================================
echo "рџ”§ STEP 1.8.1: Fixing Network Manager for LXC and installing Chromium..."

# Fix NetworkManager configuration for LXC
echo "   - Fixing Network Manager configuration..."
sed -i 's/managed=false/managed=true/' /etc/NetworkManager/NetworkManager.conf

# Restart NetworkManager to apply changes
echo "   - Restarting Network Manager..."
systemctl restart NetworkManager
sleep 2

# Create Ethernet connection for eth0
echo "   - Checking available network interfaces..."
ip link show | grep -E "(eth0|enp)" || echo "   Note: No eth0 interface found, will create generic connection"

echo "   - Creating Ethernet connection..."
# Try to create connection for existing interface, or create generic one
if ip link show eth0 >/dev/null 2>&1; then
    nmcli connection add type ethernet con-name "Wired Network" ifname eth0 autoconnect yes 2>/dev/null || echo "   Note: Failed to create eth0 connection"
else
    nmcli connection add type ethernet con-name "Wired Network" autoconnect yes 2>/dev/null || echo "   Note: Failed to create generic connection"
fi

# Set high priority for auto-connection
nmcli connection modify "Wired Network" connection.autoconnect-priority 100 2>/dev/null || echo "   Note: Failed to set priority"

echo "   - Current connections:"
echo "   - Network setup summary:"
echo "     - NetworkManager status: $(systemctl is-active NetworkManager 2>/dev/null || echo 'not active')"
echo "     - systemd-networkd status: $(systemctl is-active systemd-networkd 2>/dev/null || echo 'not active')"
echo "     - Available interfaces: $(ip link show | grep -c UP || echo 'none')"
echo "   - Setting up systemd-networkd as fallback..."
echo "     Creating systemd-networkd configuration for eth0..."
mkdir -p /etc/systemd/network
cat > /etc/systemd/network/10-eth0.network << EOF
[Match]
Name=eth0

[Network]
DHCP=yes
EOF

echo "     Enabling systemd-networkd..."
systemctl enable systemd-networkd 2>/dev/null || echo "     Note: systemd-networkd already enabled"
nmcli connection show --active 2>/dev/null || echo "   Note: No active connections"

# Install Chromium browser
echo "   - Installing Chromium browser..."
apt install -y chromium-browser || echo "   Note: Chromium installed as snap package"

# Add snap to PATH for Chromium
echo "   - Updating PATH for Chromium..."
echo "export PATH=\$PATH:/snap/bin" >> /home/sip/.bashrc

# Test browser installation
echo "   - Testing browser installation..."
su - sip -c "which chromium-browser || which chromium || echo 'Browser not found in PATH'" || true

echo "рџ“‹ Network Manager fixes and Chromium installation completed!"

# =======================================================================
# =======================================================================
# =======================================================================
# NOMACHINE REMOTE DESKTOP INSTALLATION (Advanced Version)
# =======================================================================
echo "рџ”§ STEP 1.8.2: Installing NoMachine remote desktop server..."

# РњРёРЅРё-РёРЅСЃС‚Р°Р»Р»РµСЂ NoMachine (latest .deb РґР»СЏ С‚РµРєСѓС‰РµР№ Р°СЂС…РёС‚РµРєС‚СѓСЂС‹)
# РЈСЃС‚РѕР№С‡РёРІ Рє СЂРµРґРёСЂРµРєС‚Р°Рј/РєСѓРєРё Рё РґР°С‘С‚ РїРѕРґСЂРѕР±РЅС‹Рµ Р»РѕРіРё.

ARCH="$(dpkg --print-architecture)"    # amd64 / arm64 Рё С‚.Рґ.
UA='Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Safari/537.36'
ACCEPT_LANG='en;q=0.9,ru;q=0.8'
TMPDIR="$(mktemp -d -t nomx-XXXXXX)"
CJ="$TMPDIR/cookies.txt"
PRIMARY_URL="https://www.nomachine.com/download/download&id=1"
ALT_URL="https://download.nomachine.com/download/?id=1&platform=linux"
TS="$(date +%s)" # cache-bust

# РЈР±РµРґРёРјСЃСЏ, С‡С‚Рѕ РµСЃС‚СЊ curl/ca-certificates
if ! command -v curl >/dev/null 2>&1; then
  apt-get update -y >/dev/null 2>&1
  apt-get install -y curl ca-certificates >/dev/null 2>&1
fi

log() { echo "$@"; }

fetch_html () {
  local url="$1"
  log "   -> GET $url"
  # РѕС‚РґРµР»СЊРЅС‹Р№ cookie-jar РєР°Р¶РґС‹Р№ Р·Р°РїСѓСЃРє; РѕРіСЂР°РЅРёС‡РёРј СЂРµРґРёСЂРµРєС‚С‹; РїРѕРґР»РѕР¶РёРј Р·Р°РіРѕР»РѕРІРєРё
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
  # РС‰РµРј СЃС‚СЂРѕРіРѕ <a id="link_download" href="...deb">
  sed -n 's/.*id="link_download" href="\([^"]*\.deb\)".*/\1/p' | head -n1
}

parse_link_arch() {
  # Р¤РѕР»Р±СЌРє: Р»СЋР±Р°СЏ СЃСЃС‹Р»РєР° РЅР° nomachine_*_ARCH.deb
  sed -n "s|.*href=\"\\([^\"]*nomachine_[^\"]*_${ARCH}\\.deb\\)\".*|\\1|p" | head -n1
}

follow_meta_refresh() {
  sed -n 's/.*http-equiv="refresh".*url=\([^"]*\)".*/\1/p' | head -n1
}

log " - Fetching latest NoMachine .deb link..."
DL_URL=""

# 1) primary СЃ cache-bust
HTML="$(fetch_html "${PRIMARY_URL}&_ts=${TS}" 2>/dev/null || true)"
if [[ -z "${HTML:-}" ]]; then
  log "   ! Primary returned empty. Trying ALT..."
else
  DL_URL="$(printf '%s\n' "$HTML" | parse_link_id 2>/dev/null || true)"
  [[ -n "$DL_URL" ]] && log "   -> Parsed via id=link_download (primary)"
fi

# 2) РµСЃР»Рё РЅРµ РЅР°С€Р»Рё вЂ” РїРѕРїСЂРѕР±СѓРµРј meta refresh РЅР° primary
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

# 3) РµСЃР»Рё РІСЃС‘ РµС‰С‘ РїСѓСЃС‚Рѕ вЂ” РёРґС‘Рј РЅР° ALT
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

# 4) С„РёРЅР°Р»СЊРЅР°СЏ РїСЂРѕРІРµСЂРєР°
if [[ -z "$DL_URL" ]]; then
  log " ! ERROR: could not parse a .deb URL for arch: ${ARCH}"
  log "   Tip: check network connectivity and site availability"
  rm -rf "$TMPDIR"
  exit 1
fi

# 5) РµСЃР»Рё id-СЃСЃС‹Р»РєР° РґР°Р»Р° РЅРµ С‚РѕС‚ Р°СЂС… вЂ” РѕС‚С„РёР»СЊС‚СЂСѓРµРј
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

# 6) РЈСЃС‚Р°РЅРѕРІРєР°
if ! dpkg -i "$PKG"; then
  log " - dpkg failed, resolving dependencies..."
  apt-get update -y >/dev/null 2>&1
  apt-get -f install -y >/dev/null 2>&1
  # РїРѕРІС‚РѕСЂРёС‚СЊ, РµСЃР»Рё РЅСѓР¶РЅРѕ
  dpkg -i "$PKG" 2>/dev/null || true
fi

log " - Cleaning up..."
rm -rf "$TMPDIR"

#echo "   - Configuring NoMachine for LXC environment..."

# Stop conflicting services
#systemctl stop nxserver 2>/dev/null || true
#systemctl disable nxserver 2>/dev/null || true

# Configure server
#CONFIG_FILE="/usr/NX/etc/server.cfg"
#if [ -f "$CONFIG_FILE" ]; then
#    sed -i 's/#CreateDisplay 0/CreateDisplay 1/' "$CONFIG_FILE" 2>/dev/null || true
#    sed -i 's/#DisplayOwner 0/DisplayOwner 1/' "$CONFIG_FILE" 2>/dev/null || true
#    echo "   вњ… Configuration updated"
#fi

# Start service
#echo "   - Starting NoMachine service..."
#systemctl enable nxserver 2>/dev/null || echo "   Note: nxserver service not available"
#systemctl start nxserver 2>/dev/null || echo "   Note: Failed to start nxserver"
#
#if systemctl is-active nxserver >/dev/null 2>&1; then
#    echo "   вњ… NoMachine service is running"
#else
#    echo "   вљ пёЏ  NoMachine service may need manual start"
#fi

log " - NoMachine installed successfully."
echo ""
echo "рџ”§ STEP 1.10: Setting up administrator privileges for user sip..."
usermod -aG sudo,video,render sip
echo 'sip ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/sip
chmod 0440 /etc/sudoers.d/sip

echo "рџ“‹ Administrator privileges configured successfully"
echo "   - User sip added to sudo, video, render groups for GPU access"
echo "   - Passwordless sudo access configured"
echo "   - User can now run: sudo <command> without password"

echo ""
echo "вљ пёЏ  IMPORTANT: After installation, restart the container for GPU access to work properly"
echo "   Command: pct stop 456 && pct start 456"
echo "   Or from Proxmox web interface: Stop в†’ Start container"
echo ""
echo "рџ”Ќ After restart, you can use:"
echo "   amdgpu_top          # Interactive GPU monitoring"
echo "   amdgpu_top --json   # JSON output for scripts"
echo "   rocminfo            # GPU information"

# POST-REBOOT FIXES: Clean up duplicate connections and resolve conflicts
echo "   - Cleaning up duplicate network connections..."
nmcli connection show | grep -E "(eth0|Wired)" | grep -v "Wired Network" | awk '{print $4}' | while read uuid; do
    nmcli connection delete "$uuid" 2>/dev/null || true
done

# Disable systemd-networkd to prevent conflicts with NetworkManager
echo "   - Disabling systemd-networkd to prevent conflicts..."
systemctl stop systemd-networkd 2>/dev/null || true
systemctl disable systemd-networkd 2>/dev/null || true

# Restart NetworkManager to ensure clean state
echo "   - Restarting NetworkManager for clean state..."
systemctl restart NetworkManager
sleep 3

# Final verification
echo "   - Final network verification after fixes:"
if nmcli connection show --active | grep -q eth0; then
    echo "   вњ… Network connection active and working"
else
    echo "   вљ пёЏ  Network connection may need manual activation"
fi
