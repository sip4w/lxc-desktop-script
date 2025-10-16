## Overview
<img width="500" height="450" alt="image" src="https://github.com/user-attachments/assets/b3a550d6-151c-4643-8ada-6e6ec76b01f6" />

# LXC GUI Setup Script

Briefly: this script automates installing a GUI environment in an existing Ubuntu 24.04 LXC container. It installs Xorg, KDE Plasma ,Gnome, XRDP*, configures a headless Xorg and a user Plasma session, adds ROCm utilities for AMD GPUs Beelink ser8 8845.

## Host and Proxmox configuration
- **Host**: Proxmox VE
- **Container config**: `/etc/pve/nodes/pve/lxc/456.conf`
- **Key parameters (with brief description)**:
  - **unprivileged**: 1 — the container runs in unprivileged mode (more secure)
  - **features**: `fuse=1,keyctl=1,nesting=1` — enables FUSE, keyctl, and nested containers
  - **GPU/devices inside the container**:
    - `/dev/dri/card0` (gid=44, video), `/dev/dri/renderD128` (gid=993, render) — video devices for GPU access
    - `/dev/kfd` (gid=993) — required for ROCm support (AMD GPU compute)
    - `/dev/kvm` — emulated/passed-through KVM (for virtualization, if needed)
  - **Network**: `net0` → `bridge=vmbr1`, `ip=dhcp`, `firewall=1` — network adapter, bridge, DHCP, firewall enabled
  - **Resources**: `memory=7512`, `rootfs=20G`, `swap=512` — allocated RAM, disk size, swap
  - **Other**: `tun` is mounted; extra `cgroup2.devices.allow` rules for required char devices

Example config with comments:
```ini
arch: amd64                         # Container architecture
dev0: /dev/fuse,gid=0,mode=0660     # FUSE for user filesystems
dev1: /dev/kvm,gid=10,mode=0666     # KVM for hardware virtualization
dev2: /dev/dri/card1,gid=44,mode=0660   # GPU device for rendering/output
dev3: /dev/dri/renderD128,gid=993,mode=0660 # DRM render device
dev4: /dev/kfd,gid=993,mode=0660         # ROCm compute/GPU task queue
dev5: /dev/net/tun,gid=0,mode=0660       # TUN interface (VPN, etc.)
dev6: /dev/tty,gid=4,mode=0660           # Access to PTS/TTY
dev7: /dev/tty0,gid=5,mode=0660          # TTY0 — main terminal
dev8: /dev/tty7,gid=5,mode=0660          # TTY7 — usually Xorg/graphics
dev9: /dev/fb0,gid=44,mode=0660          # Framebuffer device
features: nesting=1,keyctl=1,mknod=1     # Nesting, keyctl, and mknod enabled
hostname: testlxc                        # Hostname
memory: 15512                            # RAM (MB)
net0: name=eth0,bridge=vmbr1,hwaddr=BC:24:11:FE:A8:49,ip=dhcp,type=veth  # Network interface, bridge, DHCP
ostype: ubuntu                           # OS type inside the container
rootfs: local-lvm:vm-105-disk-0,size=20G # Container disk
swap: 0                                  # Swap
unprivileged: 1                          # Unprivileged mode
lxc.prlimit.as: unlimited                # No limit on address space (AS); important for running large apps and workloads (e.g., video, ML)
lxc.prlimit.core: unlimited              # No limit on core dumps — allows unlimited-size core dump files for debugging purposes
lxc.prlimit.cpu: unlimited               # No limit on CPU time — process won't be killed on CPU time limit (good for long-running computations)
lxc.prlimit.data: unlimited              # No limit on data segment size — for apps with large global/static data
lxc.prlimit.fsize: unlimited             # No limit on file size (fsize); allows creating/writing files of any size (logs, dumps, data)
lxc.prlimit.locks: unlimited             # No limit on number of file locks — important for DB or file sync workloads
lxc.prlimit.memlock: unlimited           # No limit on amount of RAM that can be locked (memlock); important for RT, drivers, GPU (RDMA, CUDA, OpenCL)
lxc.prlimit.msgqueue: unlimited          # No limit on POSIX message queue size; enables unrestricted IPC through message queues
lxc.prlimit.nice: unlimited              # No limit on nice value — can change process priority arbitrarily (including negative priorities)
lxc.prlimit.nproc: unlimited             # No limit on number of processes/threads (nproc); crucial for servers, compilers, renderfarms
lxc.prlimit.rss: unlimited               # No limit on Resident Set Size (rss) — maximum physical memory for processes
lxc.prlimit.rtprio: unlimited            # No limit on realtime priority — any RT priorities can be used (RT scheduling for professional audio/video)
lxc.prlimit.sigpending: unlimited        # No limit on number of pending signals (sigpending) for a process/user; important for large system workloads
lxc.prlimit.stack: unlimited             # No limit on process stack size; for programs needing deep recursion or large local variables
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
bash /root/setup_lxc_gui.sh
```
2) Reboot the container when the script finishes.

## RDP access* dont work(
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



