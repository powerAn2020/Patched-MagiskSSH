# Patched-MagiskSSH

A Magisk / KernelSU module that bundles a modern OpenSSH server for Android, complete with a built-in WebUI for managing the service, SSH keys, and configuration — no terminal required.

Built on top of [MagiskSSH](https://gitlab.com/d4rcm4rc/MagiskSSH) with the following patches applied:

- Data directory relocated from `/data/ssh` → `/data/adb/ssh`
- `sshd` logging enabled via `-E` flag (`/data/adb/ssh/sshd.log`)
- Legacy `install.sh` replaced by a modern `customize.sh`
- Injected WebUI (Svelte) + management scripts

---

## Features

| Feature | Description |
|---------|-------------|
| 🔐 **OpenSSH server** | Full-featured sshd for Android (arm / arm64 / x86 / x86_64) |
| 🌐 **WebUI** | Browser-based dashboard via KernelSU's WebUI interface |
| 🗝️ **SSH Key Manager** | Add / remove authorized keys for `root` and `shell` users |
| ⚙️ **Config Editor** | Edit `sshd_config` directly from the browser |
| 📋 **Log Viewer** | Live and snapshot log viewing from `/data/adb/ssh/sshd.log` |
| ⚡ **Action Button** | One-tap SSH toggle from KernelSU Manager |
| 🌍 **i18n** | English / Chinese UI |

---

## Requirements

- Android **8.0 (API 26)** or higher
- [Magisk](https://github.com/topjohnwu/Magisk) or [KernelSU](https://kernelsu.org/)

---

## Installation

1. Download the latest `magisk-ssh-*.zip` from [**GitHub Releases**](../../releases) or the [Actions](../../actions) build artifacts.
2. In **Magisk / KernelSU Manager**, tap **Install from storage** and select the zip.
3. Reboot.

After reboot, the SSH server starts automatically on port **22**.

---

## Usage

### WebUI (KernelSU)

Open **KernelSU Manager → Modules → MagiskSSH → Open WebUI** to access:

- **Dashboard** — start / stop / restart sshd, view running status and port
- **Key Manager** — manage `authorized_keys` for `root` and `shell`
- **Config Editor** — edit `sshd_config` with live save
- **Log Viewer** — tail or snapshot `/data/adb/ssh/sshd.log`

### Action Button (KernelSU)

Tap the **Action** button in KernelSU Manager to toggle sshd on/off. A toast notification reports the result (port number or error).

### Connecting via SSH

```sh
# As root
ssh root@<device-ip> -p 22

# As shell user
ssh shell@<device-ip> -p 22
```

Public keys are stored in:

```
/data/adb/ssh/root/.ssh/authorized_keys
/data/adb/ssh/shell/.ssh/authorized_keys
```

---

## File Layout

```
/data/adb/ssh/              ← Persistent SSH data (survives module updates)
├── sshd_config             ← Server configuration
├── sshd.pid                ← PID file
├── sshd.log                ← Server log (enabled via -E flag)
├── root/.ssh/
│   └── authorized_keys
└── shell/.ssh/
    └── authorized_keys

$MODPATH/                   ← Module files (managed by Magisk/KernelSU)
├── opensshd.init           ← Service init script
├── service.sh              ← Boot-time autostart
├── action.sh               ← Action button handler
├── system/bin/             ← Symlinks: ssh, sshd, scp, sftp, …
├── system/usr/libexec/ssh-core/   ← Real binaries + wrapper
├── webroot/                ← Built WebUI (injected at build time)
└── scripts/                ← Management scripts (api.sh, …)
```

---

## Building from Source

The module is built entirely by GitHub Actions — no local toolchain required.

```
Push to master/main  →  build-webui job (npm build)
                     →  build-MagiskSSH job
                           ├── Clone upstream MagiskSSH
                           ├── Apply path patches (/data/ssh → /data/adb/ssh)
                           ├── Cross-compile with NDK r25c
                           ├── Inject WebUI + scripts + customize.sh
                           └── Upload zip artifact
```

To trigger a build manually: **Actions → Build Magisk SSH → Run workflow**.

### Local WebUI Development

```sh
cd ui-src
npm install
npm run dev       # dev server at http://localhost:5173
npm run build     # output → ../webroot/
```

The WebUI is built with **Svelte + Vite + TypeScript** and communicates with the device via KernelSU's `ksu.exec()` / `ksu.spawn()` bridge, calling `scripts/api.sh` on the device.

---

## Scripts Reference

| Script | Location | Purpose |
|--------|----------|---------|
| `customize.sh` | module root | Magisk/KernelSU install hook — extracts and places all files |
| `service.sh` | module root | Boot autostart — starts sshd on every boot |
| `action.sh` | module root | KernelSU action button — toggles sshd |
| `api.sh` | `scripts/` | WebUI backend — dispatches all UI actions |

`api.sh` actions: `status` · `start` · `stop` · `restart` · `read_config` · `write_config` · `read_keys` · `write_keys` · `add_key` · `delete_key` · `read_log` · `tail_log`

---

## Credits

- [MagiskSSH](https://gitlab.com/d4rcm4rc/MagiskSSH) by d4rcm4rc — upstream OpenSSH Magisk module
- [OpenSSH](https://www.openssh.com/) — the SSH implementation
- [KernelSU](https://kernelsu.org/) — root solution and WebUI bridge
