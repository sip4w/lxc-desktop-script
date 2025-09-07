## Overview

This script automates the setup of a complete GUI environment within an existing LXC container. It installs KDE Plasma desktop, XRDP for remote desktop access, VNC servers, and configures GPU support with ROCm drivers. The script is designed for Ubuntu 24.04 and includes comprehensive error handling and rollback capabilities.

## System Requirements

- **Operating System**: Ubuntu 24.04
- **Architecture**: amd64 (x86_64)
- **LXC Container**: Existing privileged LXC container
- **GPU Support**: AMD GPUs (optional, with ROCm)
- **Network**: Internet connection for package downloads

## Main Components Installed

### Desktop Environment
- **KDE Plasma Desktop** - Complete desktop environment
- **SDDM** - Display manager for KDE
- **KDE Frameworks** - Essential KDE libraries and components

### Xorg Display Server
- **Xorg Core** - Display server with hardware acceleration
- **Video Drivers**: AMDGPU, Intel, NVIDIA, VMware, QXL, VirtualBox
- **Input Drivers**: libinput, wacom, keyboard, mouse

### Remote Desktop Solutions
- **XRDP** - Microsoft RDP protocol server
- **X11VNC** - VNC server for X11 sessions
- **TigerVNC** - Enhanced VNC implementation
- **NoMachine** - High-performance remote desktop (auto-downloaded latest version)

### GPU Support (ROCm)
- **ROCm System Management Interface** (`rocm-smi`)
- **ROCm Info Tool** (`rocminfo`)
- **AMD HIP Runtime** (`libamdhip64-5`)
- **Mesa Vulkan Drivers**
- **AMDGPU Top** - Real-time GPU monitoring tool (Rust-based)

### Networking
- **NetworkManager** - Network configuration management
- **systemd-networkd** - Fallback network configuration
- **V2RayA** - VPN/proxy client with web interface

### Additional Tools
- **Chromium Browser** - Web browser with GPU acceleration
- **DBus-X11** - X11 session management
- **Zenity** - GTK dialog boxes for scripts
- **Development Tools**: curl, wget, git, vim, htop, sudo

## User Configuration

### Default User
- **Username**: `sip`
- **Password**: `sip`
- **Groups**: sudo, video, render (for GPU access)
- **Permissions**: Passwordless sudo access

## Services Configured

### Systemd Services
- `xorg-headless.service` - Headless Xorg server on VT11
- `plasma-headless@sip.service` - KDE Plasma session for user sip
- `xrdp.service` - RDP server
- `xrdp-sesman.service` - RDP session manager
- `x11vnc@sip.service` - Alternative VNC server
- `v2raya.service` - V2RayA VPN client
- `NetworkManager.service` - Network management

### Xorg Configuration
- **Resolution**: 1920x1080 @ 60Hz
- **GPU Driver**: AMDGPU with TearFree option
- **Monitor**: Headless configuration
- **AccelMethod**: glamor (hardware acceleration)

## Network Configuration

### Primary Setup
- **NetworkManager** - Manages network connections
- **DHCP** - Automatic IP address assignment
- **Connection**: "Wired Network" for eth0 interface

### Fallback Configuration
- **systemd-networkd** - Alternative network management
- **Configuration File**: `/etc/systemd/network/10-eth0.network`

## GPU Monitoring

### AMDGPU Top
- **Installation**: Via Cargo/Rust toolchain
- **Features**:
  - Real-time GPU usage monitoring
  - Temperature and power consumption
  - Memory usage statistics
  - JSON output support for scripting

### ROCm Tools
- **rocm-smi**: System management interface
- **rocminfo**: GPU information display

## Remote Access Options

### RDP (Port 3389)
- **Server**: XRDP with XorgXRDP backend
- **Resolution**: Configurable, default 1920x1080
- **Authentication**: Username/password
- **Client**: Any RDP client (Remmina, Windows RDP, etc.)

### NoMachine
- **Protocol**: NX technology for better performance
- **Installation**: Automatic download of latest version
- **Architecture**: Auto-detection (amd64/arm64)
- **Configuration**: Optimized for LXC environment

## Usage Instructions

### Running the Script
```bash
chmod +x setup_lxc_gui_v1.1.sh
./setup_lxc_gui_v1.1.sh
```

### Post-Installation Steps
1. **Restart Container**: Required for GPU access
   ```bash
   pct stop <container_id> && pct start <container_id>
   ```

2. **Connect via RDP**:
   - **Host**: Container IP address
   - **Port**: 3389
   - **Username**: sip
   - **Password**: sip

3. **Monitor GPU**:
   ```bash
   amdgpu_top          # Interactive monitoring
   rocminfo           # GPU information
   rocm-smi           # System management
   ```

### Service Management
```bash
# Check status
systemctl status plasma-headless@sip
systemctl status xrdp

# View logs
journalctl -u plasma-headless@sip -f
journalctl -u xrdp -f
```

## Troubleshooting

### Common Issues
1. **GPU Not Detected**: Restart container after installation
2. **Network Issues**: Check NetworkManager vs systemd-networkd conflicts
3. **Display Problems**: Verify Xorg configuration in `/etc/X11/xorg.conf.d/`
4. **Service Failures**: Check logs with `journalctl -u <service_name>`

## Security Considerations

- **Default Password**: Change `sip:sip` after setup
- **VNC Access**: Configure passwords for VNC servers
- **Firewall**: Configure iptables for remote access ports
- **User Permissions**: Review sudo access for production use

## Dependencies

### Build Tools
- **Cargo/Rust**: For AMDGPU top compilation
- **Build Essentials**: GCC, make, etc.

### Runtime Dependencies
- **X11 Libraries**: For GUI applications
- **Qt5/KF5**: KDE framework dependencies
- **Vulkan/Mesa**: GPU acceleration
- **PipeWire**: Audio/video streaming

This script provides a complete, beta GUI environment for LXC containers with comprehensive remote access options and GPU support.
