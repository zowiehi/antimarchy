#!/usr/bin/env bash
set -euo pipefail

echo "==> Reverting Antimarchy configuration..."

# 1. Remove wrappers and shims
rm -f "$HOME/.local/bin/omarchy-default-agent"
rm -f "$HOME/.local/bin/omarchy-agent"
rm -f "$HOME/.local/bin/gemini"

# 2. Restore Hyprland bindings if modified
HYPR_BINDINGS="$HOME/.config/hypr/bindings.lua"
if [[ -f "$HYPR_BINDINGS" ]]; then
  sed -i '/Agent (Antigravity)/d' "$HYPR_BINDINGS" 2>/dev/null || true
  sed -i '/hl.unbind("SUPER + SHIFT + A")/d' "$HYPR_BINDINGS" 2>/dev/null || true
  sed -i '/hl.unbind("SUPER + SHIFT + CTRL + A")/d' "$HYPR_BINDINGS" 2>/dev/null || true
fi

# 3. Reload Hyprland if active
if command -v hyprctl &>/dev/null; then
  hyprctl reload 2>/dev/null || true
fi

echo "✅ Antimarchy configuration has been reverted."
