# ASDF Installer – Latest Version

This repository provides a **simple, automated installer** for the latest version of [ASDF](https://asdf-vm.com/), a powerful version manager for multiple runtimes such as **Python, Java, Node.js, Ruby, and more**.

The script automatically:
- Detects your **operating system** and **architecture**.
- Downloads the **latest ASDF release** from GitHub.
- Validates the **MD5 checksum**.
- Installs ASDF into `/usr/local/bin` (or `$HOME/.local/bin` if no root access).

---

## **Quick Install**
Run the command below to install ASDF:
```bash
curl -fsSL https://raw.githubusercontent.com/codeinloop/asdf-installer/main/install-latest-asdf.sh | bash
