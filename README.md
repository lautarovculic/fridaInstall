# fridaInstall

> Push & launch the latest `frida-server` to any connected Android device with a single script.
> Automatically detects ABI, downloads the correct release, and runs it as root.

---

## Features

- Auto-detect connected ADB device
- Auto-detect architecture (arm64, arm, x86, x86_64)
- Downloads latest `frida-server` from GitHub releases
- Pushes and executes the server with root privileges
- Minimal dependencies, easy to maintain

---

## Requirements

- `adb` (Android Debug Bridge)
- `curl` (for downloading)
- `jq` (for parsing GitHub API)
- `xz` (for decompressing the `.xz` frida binaries)
- Rooted Android device with ADB access

---

## Usage

```bash
chmod +x fridaInstall.sh
./fridaInstall.sh
```
Once the script finishes:
```bash
frida-ps -Uai
```
Ensure your local Frida client matches the same version as the `frida-server` that was downloaded.

## Installing Latest Frida Client (host)

> If you get this error:
```bash
Failed to enumerate applications: unable to communicate with remote frida-server; please ensure that major versions match
```
That means your local Frida client is outdated. Update it as follows:

### pip (inside virtualenv or globally)
```bash
pip install -U frida frida-tools
```

### pipx (preferred)
```bash
pipx upgrade frida-tools
```

Or install an exact version:
```bash
pipx uninstall frida-tools
pipx install frida-tools==17.0.1
```

## Author
Made with love by Lautaro D. Villarreal Culic'
https://lautarovculic.com
