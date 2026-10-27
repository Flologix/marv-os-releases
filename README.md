# Marv OS (beta)

Downloads, release notes and feedback for the **Marv OS desktop beta** by [FloLogix AI](https://flologixai.com).

Marv OS is the Marv desktop app for running several coding agents on your own machine: see what each one is doing, what needs you, and what happened while you were away. It's built on the open-source [Marv](https://github.com/Flologix/marv) engine.

This repository holds **binaries only**: no source code.

## Install

You'll need a model provider: an OpenRouter key, a ChatGPT or Z.ai plan, or Ollama running locally. The first run walks you through it.

Every download is listed with a checksum in `SHA256SUMS` on the [Releases](https://github.com/Flologix/marv-os-releases/releases) page. Releases are marked "pre-release" while Marv OS is in beta.

### Linux (x86_64)

One command:

```sh
curl -fsSL https://raw.githubusercontent.com/Flologix/marv-os-releases/main/install.sh | sh
```

On Debian and Ubuntu it installs the `.deb` with apt (the only step that uses `sudo`, and it says so first). Elsewhere it puts the AppImage at `~/.local/bin/marv-os` and adds an app menu entry. It checks the download against `SHA256SUMS` before installing, and runs nothing else from the network. Set `MARV_OS_VERSION=1.0.0-beta.1` to pin a version. Read the script first if you like: [install.sh](install.sh).

Manually, from [Releases](https://github.com/Flologix/marv-os-releases/releases):

- **AppImage:** `chmod +x Marv*.AppImage && ./Marv*.AppImage`
- **Debian/Ubuntu:** `sudo apt install ./marv-os_*.deb`

Marv OS runs commands in a sandbox, so install `bubblewrap` if your distribution doesn't have it (`sudo pacman -S bubblewrap`, `sudo dnf install bubblewrap`, `sudo zypper install bubblewrap`). The `.deb` pulls it in for you.

### macOS (Apple silicon)

Download `Marv_<version>_aarch64.dmg` from Releases and drag Marv to Applications. The beta isn't signed or notarized yet, so macOS will refuse to open it the first time: **right-click Marv, choose Open, then Open again.** You only need to do this once.

### Windows (WSL2, experimental)

Marv OS runs on Windows inside WSL2 (Windows 10 21H2 or later, or Windows 11) and opens as a normal window through WSLg. There's no native Windows build yet, and this route is experimental.

In PowerShell:

```powershell
irm https://raw.githubusercontent.com/Flologix/marv-os-releases/main/install-windows.ps1 | iex
```

It installs WSL2 with Ubuntu 24.04 if you don't have it (Windows may ask for a restart: run the command again afterwards), then runs the Linux installer inside Ubuntu. Read it first: [install-windows.ps1](install-windows.ps1).

Manually:

1. In PowerShell: `wsl --install -d Ubuntu-24.04`, restart if asked, and finish Ubuntu's first-run setup.
2. `wsl --update`
3. In Ubuntu, run the Linux one-liner above.
4. Start Marv OS from the Start menu, or run `wsl -d Ubuntu-24.04 marv-desktop`.

If the window doesn't open, run `wsl --update` and `wsl --shutdown`, then try again.

## Beta notes

- This is a beta: expect rough edges, and keep backups of work you care about.
- Commands run in a sandbox (bubblewrap) on Linux.

## What leaves your machine

Nothing from Marv OS itself: it has no telemetry, analytics or crash reporting, and no account or sign-up. The only network traffic is to the model provider you configure (OpenRouter, ChatGPT, Z.ai or your own Ollama), carrying your prompts and the context the agents send. If you use OpenRouter, the app also reads OpenRouter's public model list (`openrouter.ai/api/v1/models`) to fill the model picker; that request carries no data from you. Anything an agent does on your behalf, such as a `git push` or a web request in a command you approved, is of course up to that command.

## Feedback

Open an issue: [report a bug](https://github.com/Flologix/marv-os-releases/issues/new?template=bug.yml) or [share feedback](https://github.com/Flologix/marv-os-releases/issues/new?template=feedback.yml). Please never paste API keys or private code into an issue.

© FloLogix AI. All rights reserved. The open-source Marv engine is MIT-licensed; the Marv OS desktop is not.
