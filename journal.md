# 📓 Homelab Journal

A running log of what I've built, broken, and learned along the way.

---

## Entry 1 — July 29, 2026: Homelab Setup Begins

**Goal:** Set up my first virtual machine to start building hands-on IT/security skills.

**What I did:**
- Chose **UTM** as my hypervisor after discovering that VirtualBox has weak/unreliable support on Apple Silicon Macs (M1–M4). UTM uses Apple's native virtualization framework, making it a much better fit for my hardware.
- Downloaded Ubuntu Server to create my first VM.

**Issues encountered (and how I solved them):**
1. **Architecture mismatch** — My first VM creation attempt failed because I had downloaded the `amd64` (Intel/x86) version of the Ubuntu ISO, but my Mac's Apple Silicon chip requires an `arm64` build. Fixed by re-downloading the correct ARM64 ISO.
2. **Torrent file instead of ISO** — On a later attempt, I discovered the file I'd downloaded was actually a `.iso.torrent` file, not the real disk image, which is why the VM showed almost no disk usage. Solved by finding the direct ISO download link instead of the torrent option.
3. **Boot loop after installation** — After installation completed, the VM kept booting back into the installer instead of the newly installed OS. This was because UTM didn't automatically eject the installation ISO. Fixed by manually detaching the ISO from the VM's virtual CD/DVD drive in settings before rebooting.

**Result:** Successfully installed **Ubuntu 26.04 LTS** as my first working homelab VM.

**Skills practiced:**
- Basic Linux CLI navigation: `whoami`, `pwd`, `ls`, `cd`, `mkdir`, `touch`
- Package management: `sudo apt update`, `sudo apt upgrade`
- Using `sudo` and authenticating with a password in the terminal
- Reading and interpreting boot logs / systemd service output
- General VM troubleshooting: architecture compatibility, boot media, boot order

**Next steps:**
- Set up SSH access to the VM for remote practice
- Add a second VM (Kali Linux) for security tooling practice
- Start researching Active Directory lab setup (likely via a cloud VM, since Windows Server has limited support on Apple Silicon)

---

Entry 2 — July 30, 2026: SSH Remote Access

Goal: Set up SSH so I can control my Ubuntu VM remotely from my Mac's terminal instead of the UTM window.

What I did:

- Installed the OpenSSH server on my Ubuntu VM: `sudo apt install openssh-server`
- Discovered the service was installed but disabled by default — started and enabled it with `sudo systemctl start ssh` and `sudo systemctl enable ssh`
- Verified it was running with `sudo systemctl status ssh` (confirmed `active (running)`)
- Found my VM's internal IP address using `ip addr` (identified the correct network interface, `enp0s1`, vs. the loopback interface `lo`)
- Successfully connected from my Mac's native Terminal using `ssh username@vm-ip-address`, accepted the host key fingerprint, and authenticated with my password

Skills practiced:

- Managing systemd services (`start`, `enable`, `status`)
- Reading network interface output to identify the correct IP address
- Understanding SSH host key verification and first-time connection warnings
- Remote login and authentication over SSH

Entry 3 — July 31, 2026: File Transfer, SSH Keys, and Kali Linux Troubleshooting

Goal: Practice secure file transfer over SSH, set up passwordless authentication, and add Kali Linux as a second VM.

What I did:

Transferred a test file from my Mac to the Ubuntu VM using scp, confirmed successful transfer by checking file contents on the receiving end with cat
Generated an SSH key pair on my Mac with ssh-keygen -t ed25519
Installed my public key on the Ubuntu VM using ssh-copy-id
Confirmed passwordless SSH login now works — no more typing a password for every connection
Attempted to set up Kali Linux (ARM64 Installer) as a second VM in UTM

Issues encountered:

Kali VM hung on a black screen after selecting "Install" from the GRUB boot menu, showing "Guest has not initialized the display (yet)"
Diagnosed using Activity Monitor — found the QEMU process for the Kali VM running at 200%+ CPU, ruling out a simple freeze and suggesting the VM was actively working but not rendering
Switched the emulated display card from a virtio option to VGA (a more universally compatible option) — issue persisted
Verified the downloaded Kali ISO file size (3.97 GB) matched expectations, ruling out a corrupted/incomplete download
Concluded this is likely a deeper UTM/QEMU + Kali ARM64 compatibility issue rather than a simple config fix — will continue troubleshooting next session (options to try: NetInstaller image, explicit CPU core allocation, community forum research, or installing security tools directly on the existing Ubuntu VM as an alternative)

Skills practiced:

Secure file transfer with scp
SSH key-based authentication (ssh-keygen, ssh-copy-id)
Using Activity Monitor to diagnose VM resource usage
Systematic troubleshooting: isolating variables (display driver, file integrity, CPU) one at a time rather than guessing

Next steps:

Resolve Kali Linux VM display/boot issue
Consider Active Directory lab setup (likely cloud VM)

 "Entry 4 — [Date]" 

