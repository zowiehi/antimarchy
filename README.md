# Antimarchy

[![Omarchy Plugin](https://img.shields.io/badge/omarchy-plugin-blue.svg)](https://omarchy.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Antimarchy** provides seamless, first-class integration for **Google Antigravity (`agy`)** as your default AI coding agent in **Omarchy Linux**.

---

## 🌟 Features

- ⚡ **Native Agent Integration**: Sets `agy` as your default coding agent across the entire Omarchy desktop environment.
- ⌨️ **Dedicated Keybindings**: Launches Antigravity directly in an Omarchy-styled agent terminal window via **`Super + Shift + A`** or **`Super + Shift + Ctrl + A`**.
- 📋 **System Menu Option**: Adds **Antigravity (agy)** directly under **Setup > Defaults > Agent** in the Quickshell Omarchy menu (`Super + Space`).
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
| **`Super + Shift + A`** | Launch Antigravity in floating/tiled agent window |
| **`Super + Shift + Ctrl + A`** | Launch Antigravity in floating/tiled agent window |
| **`Super + Space`** | Open Omarchy Menu → **Setup > Defaults > Agent** |

---

## 🛠️ Prerequisites

- **Omarchy Linux** (Quickshell / Hyprland)
- **Antigravity CLI** (`agy`):
  ```bash
  yay -S antigravity-cli
  # or follow official install instructions
  agy auth login
  ```

---

## 📄 License

MIT License. See [LICENSE](./LICENSE) for details.
