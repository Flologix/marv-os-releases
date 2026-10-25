# Marv OS (beta)

Downloads, release notes and feedback for the **Marv OS desktop beta** by [FloLogix AI](https://flologixai.com).

Marv OS is the Marv desktop app for running several coding agents on your own machine: see what each one is doing, what needs you, and what happened while you were away. It's built on the open-source [Marv](https://github.com/FlologixAI/marv) engine.

This repository holds **binaries only**: no source code.

## Install (Linux)

Download the latest release from [Releases](https://github.com/FlologixAI/marv-os-releases/releases):

- **AppImage:** `chmod +x Marv*.AppImage && ./Marv*.AppImage`
- **Debian/Ubuntu:** `sudo apt install ./marv-os_*.deb`

Check the download against `SHA256SUMS` in the release.

You'll need a model provider: an OpenRouter key, a ChatGPT or Z.ai plan, or Ollama running locally. The first run walks you through it.

macOS and Windows builds aren't available yet.

## Beta notes

- This is a beta: expect rough edges, and keep backups of work you care about.
- Commands run in a sandbox (bubblewrap); install `bwrap` if your distribution doesn't ship it.
- Nothing is sent anywhere except to the model provider you choose.

## Feedback

Open an issue: [report a bug](https://github.com/FlologixAI/marv-os-releases/issues/new?template=bug.yml) or [share feedback](https://github.com/FlologixAI/marv-os-releases/issues/new?template=feedback.yml). Please never paste API keys or private code into an issue.

© FloLogix AI. All rights reserved. The open-source Marv engine is MIT-licensed; the Marv OS desktop is not.
