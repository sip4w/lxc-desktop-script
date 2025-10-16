## Overview
<img width="500" height="450" alt="image" src="https://github.com/user-attachments/assets/b3a550d6-151c-4643-8ada-6e6ec76b01f6" />

# LXC GUI Setup Script

Briefly: this script automates installing a GUI environment in an existing Ubuntu 24.04 LXC container. It installs Xorg, KDE Plasma, XRDP, configures a headless Xorg and a user Plasma session, adds ROCm utilities for AMD GPUs.

## Host and Proxmox configuration
- **Host**: Proxmox VE
- **Container config**: `/etc/pve/nodes/pve/lxc/456.conf`
- **Key parameters**:
  - **unprivileged**: 1 (unprivileged container)
  - **features**: `fuse=1,keyctl=1,nesting=1`
  - **GPU/devices inside the container**:
    - `/dev/dri/card0` (gid=44, video), `/dev/dri/renderD128` (gid=993, render)
    - `/dev/kfd` (gid=993) — for ROCm
    - `/dev/kvm` — passed through (if required)
  - **Network**: `net0` → `bridge=vmbr1`, `ip=dhcp`, `firewall=1`
  - **Resources**: `memory=7512`, `rootfs=20G`, `swap=512`
  - **Other**: `tun` mounted; extra `cgroup2.devices.allow` rules for required char devices

Example snippet:
```ini
unprivileged: 1
features: fuse=1,keyctl=1,nesting=1
dev2: /dev/dri/card0,gid=44,mode=0660
dev3: /dev/dri/renderD128,gid=993,mode=0660
dev4: /dev/kfd,gid=993,mode=0660
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file
lxc.mount.entry: /dev/shm dev/shm none bind,create=dir,optional
net0: name=eth0,bridge=vmbr1,firewall=1,ip=dhcp,type=veth
```

> Note: inside the container, user `sip` is added to `video` and `render` groups which match the passed GPU devices.

## Notes
- The script targets AMD GPUs (ROCm). If no GPU is available, Xorg may fail with the `amdgpu` driver. In that case, use the dummy/vesa driver or configure device passthrough properly.
- The hint `pct stop 456 && pct start 456` is an example; use your actual container ID.


## Features
- Headless Xorg (+ custom `xorg.conf.d/10-headless-amdgpu.conf`, 1920x1080, `amdgpu` driver)
- KDE Plasma (X11) as a system service `plasma-headless@<user>`
- RDP access via XRDP (port 3389)
- ROCm tools: `rocm-smi`, `rocminfo`, `libamdhip64-*`; builds `amdgpu_top`
- NoMachine .deb downloader (install only; service start/config commented out)

## Requirements
- Ubuntu 24.04 inside LXC (unprivileged container)
- Internet connectivity
- systemd inside the container
- For GPU: `/dev/dri/*` passthrough (AMD), proper cgroup rules, and access to `video` and `render` groups

## Quick start
1) Run as `root` inside the container:
```bash
bash /root/setup_lxc_gui_v1.1.sh
```
2) Reboot the container when the script finishes.

## RDP access
- Host: container IP
- Port: 3389
- User: `sip`
- Password: `sip`

## Important (security and caveats)
- Change the `sip` user password immediately and preferably remove `NOPASSWD:ALL` from `/etc/sudoers.d/sip`.
- Xorg starts with `-ac` (no access control); restrict network access via firewall.
- `chromium-browser` may require snap: install `snapd && snap install chromium` or use `apt install -y firefox`.

## Troubleshooting
```bash
systemctl status xorg-headless
systemctl status plasma-headless@sip
systemctl status xrdp xrdp-sesman
journalctl -u plasma-headless@sip -f
rocminfo
amdgpu_top
```



