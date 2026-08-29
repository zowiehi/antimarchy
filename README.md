# Antimarchy

[![Omarchy Plugin](https://img.shields.io/badge/omarchy-plugin-blue.svg)](https://omarchy.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Antimarchy** provides seamless, first-class integration for **Google Antigravity (`agy`)** as your default AI coding agent in **Omarchy Linux**.

---

## 🌟 Features

- ⚡ **Native Agent Integration**: Sets `agy` as your default coding agent across the entire Omarchy desktop environment.
- 📦 **Automated CLI Installation**: Automatically detects and installs `antigravity-cli` via AUR (`yay`/`paru`) if not already present on the system.
- 🔝 **Top of Menu**: Places **Antigravity** at the very top of the **Setup > Defaults > Agent** menu in Quickshell (`Super + Space`).
- ⌨️ **Dedicated Keybinding**: Launches Antigravity directly in an Omarchy-styled agent terminal window via **`Super + Shift + Ctrl + A`**.
- 🛡️ **Deprecation Bridge**: Safely removes stale Gemini CLI installations from Mise and maps legacy calls to `agy --dangerously-skip-permissions`.

---

## 🚀 Installation

### Option 1: Via Omarchy Plugin Manager (Recommended)

```bash
omarchy plugin add https://github.com/zowiehi/antimarchy.git --enable --yes
~/.config/omarchy/plugins/zowiehi.antimarchy/bin/setup.sh
```

### Option 2: Via Git & Setup Script

```bash
git clone https://github.com/zowiehi/antimarchy.git ~/.config/omarchy/plugins/zowiehi.antimarchy
~/.config/omarchy/plugins/zowiehi.antimarchy/bin/setup.sh
```

---

## ⌨️ Shortcuts

| Shortcut | Action |
| :--- | :--- |
| **`Super + Shift + Ctrl + A`** | Launch Antigravity in dedicated agent window |
| **`Super + Space`** | Open Omarchy Menu → **Setup > Defaults > Agent** |

---

## 📄 License

MIT License. See [LICENSE](./LICENSE) for details.
