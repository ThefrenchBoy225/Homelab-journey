# 📓 Homelab Journal

A running log of what I've built, broken, and learned along the way.

---

## Entry 1 — July 29, 2026: Homelab Setup Begins

**Goal:** Set up my first virtual machine to start building hands-on IT/security skills.

### What I did
- Chose **UTM** as my hypervisor after discovering that VirtualBox has weak/unreliable support on Apple Silicon Macs (M1–M4). UTM uses Apple's native virtualization framework, making it a much better fit for my hardware.
- Downloaded Ubuntu Server to create my first VM.

### Issues encountered (and how I solved them)
1. **Architecture mismatch** — My first VM creation attempt failed because I had downloaded the `amd64` (Intel/x86) version of the Ubuntu ISO, but my Mac's Apple Silicon chip requires an `arm64` build. Fixed by re-downloading the correct ARM64 ISO.
2. **Torrent file instead of ISO** — On a later attempt, I discovered the file I'd downloaded was actually a `.iso.torrent` file, not the real disk image, which is why the VM showed almost no disk usage. Solved by finding the direct ISO download link instead of the torrent option.
3. **Boot loop after installation** — After installation completed, the VM kept booting back into the installer instead of the newly installed OS. This was because UTM didn't automatically eject the installation ISO. Fixed by manually detaching the ISO from the VM's virtual CD/DVD drive in settings before rebooting.

### Result
Successfully installed **Ubuntu 26.04 LTS** as my first working homelab VM.

### Skills practiced
- Basic Linux CLI navigation: `whoami`, `pwd`, `ls`, `cd`, `mkdir`, `touch`
- Package management: `sudo apt update`, `sudo apt upgrade`
- Using `sudo` and authenticating with a password in the terminal
- Reading and interpreting boot logs / systemd service output
- General VM troubleshooting: architecture compatibility, boot media, boot order

### Next steps
- Set up SSH access to the VM for remote practice
- Add a second VM (Kali Linux) for security tooling practice
- Start researching Active Directory lab setup (likely via a cloud VM, since Windows Server has limited support on Apple Silicon)

---

## Entry 2 — July 30, 2026: SSH Remote Access

**Goal:** Set up SSH so I can control my Ubuntu VM remotely from my Mac's terminal instead of the UTM window.

### What I did
- Installed the OpenSSH server on my Ubuntu VM: `sudo apt install openssh-server`
- Discovered the service was installed but disabled by default — started and enabled it with `sudo systemctl start ssh` and `sudo systemctl enable ssh`
- Verified it was running with `sudo systemctl status ssh` (confirmed `active (running)`)
- Found my VM's internal IP address using `ip addr` (identified the correct network interface, `enp0s1`, vs. the loopback interface `lo`)
- Successfully connected from my Mac's native Terminal using `ssh username@vm-ip-address`, accepted the host key fingerprint, and authenticated with my password

### Skills practiced
- Managing systemd services (`start`, `enable`, `status`)
- Reading network interface output to identify the correct IP address
- Understanding SSH host key verification and first-time connection warnings
- Remote login and authentication over SSH

### Next steps
- Try file transfer between Mac and VM using `scp`
- Consider setting up SSH key-based authentication (more secure than password-only)
- Add Kali Linux as a second VM

---

## Entry 3 — July 31, 2026: File Transfer, SSH Keys, and Kali Linux Troubleshooting

**Goal:** Practice secure file transfer over SSH, set up passwordless authentication, and add Kali Linux as a second VM.

### What I did
- Transferred a test file from my Mac to the Ubuntu VM using `scp`, confirmed successful transfer by checking file contents on the receiving end with `cat`
- Generated an SSH key pair on my Mac with `ssh-keygen -t ed25519`
- Installed my public key on the Ubuntu VM using `ssh-copy-id`
- Confirmed passwordless SSH login now works — no more typing a password for every connection
- Attempted to set up Kali Linux (ARM64 Installer) as a second VM in UTM

### Issues encountered
1. **Display/boot hang** — Kali VM hung on a black screen after selecting "Install" from the GRUB boot menu, showing "Guest has not initialized the display (yet)"
2. **Diagnosis** — Used Activity Monitor and found the QEMU process for the Kali VM running at 200%+ CPU, ruling out a simple freeze and suggesting the VM was actively working but not rendering
3. **Attempted fix** — Switched the emulated display card from a `virtio` option to VGA (a more universally compatible option) — issue persisted
4. **Ruled out corruption** — Verified the downloaded Kali ISO file size (3.97 GB) matched expectations, ruling out a corrupted/incomplete download
5. **Conclusion** — Likely a deeper UTM/QEMU + Kali ARM64 compatibility issue rather than a simple config fix — decided to continue troubleshooting next session, with options to try: NetInstaller image, explicit CPU core allocation, community forum research, or installing security tools directly on the existing Ubuntu VM as an alternative

### Skills practiced
- Secure file transfer with `scp`
- SSH key-based authentication (`ssh-keygen`, `ssh-copy-id`)
- Using Activity Monitor to diagnose VM resource usage
- Systematic troubleshooting: isolating variables (display driver, file integrity, CPU) one at a time rather than guessing

### Next steps
- Resolve Kali Linux VM display/boot issue
- Consider Active Directory lab setup (likely cloud VM)

---

## Entry 4 — August 3, 2026: Kali Troubleshooting Wrap-up & Wazuh Cloud SIEM Deployment

**Goal:** Resolve the Kali Linux VM display issue if possible, then pivot to building real security monitoring experience.

### What I did
- Attempted one more fix on the Kali VM issue from last session — increased CPU cores allocated to the VM — but the same "Guest has not initialized the display" error persisted
- Decided to stop troubleshooting Kali on this hardware and pivot to a more productive path: installing security tools directly on the existing Ubuntu VM instead of fighting a second VM's compatibility issues
- Installed core security tools on Ubuntu via `apt`: `nmap`, `netcat-traditional`, `john` (John the Ripper), `hydra`
- Researched SIEM concepts and Wazuh specifically, and decided to deploy Wazuh Cloud (free 14-day trial) rather than self-hosting, since my Mac's 8GB RAM wasn't enough to comfortably run Wazuh's all-in-one install locally
- Signed up for Wazuh Cloud using a school email (personal email domains were rejected by their signup form)
- Created a Wazuh Cloud trial environment ("Homelab - trial") in the Canada Central region
- Worked through a login issue with the auto-generated dashboard credentials — resolved itself after a short wait, likely an account provisioning delay
- Deployed a Wazuh agent onto my Ubuntu VM using the auto-generated install command (DEB aarch64 package), then started and enabled the `wazuh-agent` service
- Confirmed the agent connected successfully and is actively reporting to the dashboard

### Result
Ubuntu VM is now being actively monitored by a real, industry-standard SIEM/XDR platform. Within the first 24 hours, Wazuh detected and logged 38 total alerts, including MITRE ATT&CK-mapped events like "Sudo and Sudo Caching" and "Valid Accounts" — correctly identifying my own `sudo` usage and SSH logins from previous sessions.

![Wazuh Dashboard showing active alerts](./screenshots/Wazuh-dashboard.png)

### Skills practiced
- Systematic troubleshooting and knowing when to pivot away from a blocked approach rather than over-investing further
- Basic security tool installation (nmap, hydra, john)
- SIEM/XDR concepts: log aggregation, alert severity levels, MITRE ATT&CK framework mapping
- Deploying and configuring a Wazuh agent to report to a central manager
- Reading and interpreting a live security dashboard

### Next steps
- Explore the Threat Hunting and Events views in more depth to understand individual alerts
- Try Wireshark for network traffic analysis (lightweight, no VM required)
- Monitor the Wazuh trial expiration date and decide whether to document a teardown or continue exploring before it lapses
- Revisit Kali Linux later, possibly via a cloud VM or different hardware

---

## Entry 5 — August 4, 2026: Wireshark Traffic Capture & Simulated SSH Brute-Force Attack

**Goal:** Use Wireshark to capture and analyze network traffic from a simulated SSH brute-force attack against the Ubuntu VM, using `hydra`.

### What I did
- Installed **Wireshark** on my Mac via Homebrew, alongside `hydra` (already installed in Entry 4)
- Started a packet capture in Wireshark, initially on the Mac's Wi-Fi interface
- Ran `hydra` from the Mac terminal against the Ubuntu VM's SSH service (port 22) using a small password list, simulating a brute-force login attempt
- Filtered the capture on `ssh` to isolate relevant traffic — 371 total packets captured, 77 matching the SSH filter (~21%)
- Inspected an individual server response packet and found the raw SSH banner exposed in the hex/ASCII pane before encryption begins: `SSH-2.0-OpenSSH_10.2p1 Ubuntu-2ubuntu3.5`

### Issues encountered (and how I solved them)
1. **No VM traffic visible on Wi-Fi interface** — Capturing on the Mac's Wi-Fi adapter showed zero traffic between the host and the Ubuntu VM
2. **Diagnosis** — UTM VMs on Apple Silicon don't route traffic over the physical Wi-Fi radio; they run on a virtual/shared network backed by a bridge interface instead, so capturing on Wi-Fi only ever sees what actually leaves the Mac wirelessly
3. **Fix** — Switched the Wireshark capture interface to **`bridge100`**, the virtual bridge UTM uses to connect the host to its VMs — traffic between the host (192.168.64.1) and the Ubuntu VM (192.168.64.3) appeared immediately

### Result
Successfully captured and analyzed a full simulated SSH brute-force attack at the packet level. The capture showed two things clearly: a repeating handshake pattern (client protocol announcement → server response → key exchange init → repeat) consistent with `hydra` tearing down and rebuilding a full SSH handshake for every login attempt, and a clean banner grab confirming the exact OpenSSH version running on the target — the same kind of unencrypted fingerprinting information a real attacker would use for recon before selecting an exploit.

![SSH banner grab and repeated handshake pattern in Wireshark](./screenshots/entry5-ssh-capture.png)

### Skills practiced
- Packet capture and traffic analysis with Wireshark
- Wireshark display filters (`ssh`)
- Diagnosing virtual network topology (physical vs. bridge interfaces) on a hypervisor
- Reading raw hex/ASCII payload data to identify protocol banners
- Recognizing the network-level signature of a brute-force attack (repeated handshakes in a short window)
- Simulated offensive tooling with `hydra`

### Next steps
- Re-run this exercise once Wazuh Cloud is available again (locked out until Nov 2026) to correlate the Wireshark capture with Wazuh's alerting/MITRE ATT&CK mapping side by side
- Explore Wireshark's "Follow TCP Stream" feature on other protocols for deeper traffic analysis practice
- Consider adding an `iptables` rate-limiting rule on the Ubuntu VM to see how it changes the traffic pattern for a brute-force attempt
- Revisit Kali Linux later, possibly via a cloud VM or different hardware

## Entry 6 — August 6, 2026: Defending Against the Brute-Force with fail2ban

**Goal:** Close the loop from Entry 5 by actually defending the Ubuntu VM against the SSH brute-force attack I simulated, and prove the defense works at the packet level.

### What I did
- Installed **fail2ban** on the Ubuntu VM: `sudo apt install fail2ban -y`
- Confirmed the service installed, enabled, and was running with `sudo systemctl status fail2ban`
- Created a custom jail configuration at `/etc/fail2ban/jail.local` (rather than editing the default `jail.conf`, which can be overwritten by updates) to enable and tune the `sshd` jail:
  ```
  [sshd]
  enabled = true
  port = ssh
  filter = sshd
  logpath = /var/log/auth.log
  maxretry = 3
  findtime = 300
  bantime = 600
  ```
  This bans an IP for 10 minutes after 3 failed SSH logins within a 5-minute window
- Restarted fail2ban and verified the `sshd` jail was active with `sudo fail2ban-client status` and `sudo fail2ban-client status sshd`
- Re-ran the same `hydra` brute-force attack from Entry 5 against the Ubuntu VM
- Confirmed the ban triggered: `fail2ban-client status sshd` showed **Total failed: 5**, **Currently banned: 1**, with my Mac's IP (192.168.64.1) listed under Banned IP list
- To make testing faster, temporarily lowered `bantime` to 120 seconds, then re-ran `hydra` and immediately attempted a manual `ssh` connection from the Mac within the ban window
- The manual SSH attempt returned **`ssh: connect to host 192.168.64.3 port 22: Connection refused`** — the ban actively rejected the connection
- Captured the whole sequence in Wireshark on the `bridge100` interface and found the exact rejection packets using an `icmp` display filter

### Issues encountered (and how I solved them)
1. **nano save prompt got stuck / filename field got mangled** — while editing `jail.local`, accidentally deleted part of the filename at the "Write to File" prompt and couldn't retype it cleanly. Fixed by pressing `Ctrl+C` to cancel the prompt, then `Ctrl+K` to clear the filename line and retyping `/etc/fail2ban/jail.local` from scratch before saving
2. **First attempt to catch the block in Wireshark showed a full successful SSH session instead** — by the time I tried a manual `ssh` connection, the original 10-minute ban had already expired (too much time passed while troubleshooting nano). Confirmed with `fail2ban-client status sshd` showing `Currently banned: 0`
3. **Fix** — temporarily shortened `bantime` to 120 seconds in `jail.local` and restarted fail2ban, then re-ran `hydra` immediately followed by a manual SSH attempt within that shorter window, successfully catching the live block this time
4. **hydra's 5 parallel connection attempts all succeeded at the TCP level** — during the first successful ban capture, filtering Wireshark for SYN/SYN-ACK pairs on the attack traffic showed all 5 hydra connections got answered normally. This was expected once I thought it through: fail2ban only bans *after* reading failed login entries from `/var/log/auth.log`, and hydra's parallel connections all opened before enough failures were logged and processed — the wordlist finished before a 6th (blockable) attempt could occur

### Result
Successfully defended the Ubuntu VM against a real brute-force attack and captured proof of it at both the service level and the packet level. `fail2ban` correctly identified 3+ failed SSH logins from the same IP and began actively rejecting further connection attempts. The Mac terminal showed a hard `Connection refused`, and Wireshark confirmed why: the VM responded with an **ICMP Type 3 (Destination Unreachable), Code 3 (Port Unreachable)** packet instead of the normal TCP SYN-ACK — the network-level signature of `iptables` rejecting the connection before it ever reached the SSH service. Multiple repeated ICMP rejection packets in the capture confirmed the block held for more than one attempt.

![ICMP Destination Unreachable (Port Unreachable) packet in Wireshark, showing fail2ban actively rejecting the banned IP](./screenshots/entry6-fail2ban-icmp-reject.png)

### Skills practiced
- Installing and configuring `fail2ban`, including writing a custom jail override file
- Reading and interpreting `fail2ban-client status` output (failed attempts, ban counts, banned IPs)
- Understanding the difference between a silently dropped connection and an actively rejected one (ICMP port-unreachable vs. no response at all)
- Using Wireshark's Find Packet (`Ctrl+F`) and display filters (`icmp`, `ip.addr`) to locate specific events inside a large capture
- Correlating application-layer log behavior (fail2ban reading `auth.log`) with what actually shows up on the wire
- Iterative testing under time pressure — adjusting `bantime` to make a race-condition-prone test reliably reproducible
- systemd service management and nano file editing under real troubleshooting conditions

### Next steps
- Re-run this exercise once Wazuh Cloud is available again (locked out until Nov 2026) to see the brute-force *and* the fail2ban response reflected in Wazuh's dashboard and MITRE ATT&CK mapping
- Restore `bantime` back to a production-realistic value (600s or higher) now that testing is done
- Explore fail2ban's email/alert notification options for a more complete "detect and respond" workflow
- Revisit Kali Linux later, possibly via a cloud VM or different hardware
