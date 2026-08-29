#!/usr/bin/env bash
set -euo pipefail

echo "==> Setting up Antigravity (agy) integration for Omarchy..."

# 1. Ensure agy is available
if ! command -v agy &>/dev/null; then
  echo "⚠️  'agy' CLI not found on PATH."
  echo "   Please install Antigravity first (e.g., yay -S antigravity-cli or via official installer)."
fi

# 2. Setup user local bin directory
mkdir -p "$HOME/.local/bin" "$HOME/.config/omarchy/defaults" "$HOME/.config/omarchy/extensions"

# 3. Create omarchy-default-agent wrapper
cat << 'INNER_EOF' > "$HOME/.local/bin/omarchy-default-agent"
#!/bin/bash
agent_file="$HOME/.config/omarchy/defaults/agent"

installing=false
if [[ ${1:-} == "--install" ]]; then
  installing=true
  shift
fi

if (($# == 0)); then
  if [[ -f $agent_file ]]; then
    read -r agent <"$agent_file"
  fi
  [[ -n ${agent:-} ]] && echo "$agent"
  exit 0
fi

case "$1" in
agy | antigravity | gemini | gemini-cli)
  mkdir -p "$(dirname "$agent_file")"
  printf '%s\n' "agy" >"$agent_file"
  echo "Default coding agent set to Antigravity (agy)"
  exit 0
  ;;
*)
  if [[ $installing == "true" ]]; then
    exec /usr/share/omarchy/bin/omarchy-default-agent --install "$@"
  else
    exec /usr/share/omarchy/bin/omarchy-default-agent "$@"
  fi
  ;;
esac
INNER_EOF
chmod +x "$HOME/.local/bin/omarchy-default-agent"

# 4. Create omarchy-agent wrapper
cat << 'INNER_EOF' > "$HOME/.local/bin/omarchy-agent"
#!/bin/bash
inline=false
pick=false

while (($#)); do
  case "$1" in
    --inline)
      inline=true
      shift
      ;;
    --pick)
      pick=true
      shift
      ;;
    --prompt)
      prompt=${2:?--prompt needs a value}
      shift 2
      ;;
    *)
      echo "Unexpected argument: $1" >&2
      exit 1
      ;;
  esac
done

[[ $PWD == "$HOME" && -d $HOME/Work ]] && cd "$HOME/Work"

agent=$(omarchy-default-agent)

if [[ -z $agent ]]; then
  [[ $pick == "true" ]] && exec omarchy-menu summon setup.default.agent
  echo "Choose default agent with: omarchy default agent <name>" >&2
  exit 1
fi

case "$agent" in
agy | antigravity | gemini)
  command=(agy --dangerously-skip-permissions)
  [[ -n ${prompt:-} ]] && command+=(--prompt-interactive "$prompt")
  ;;
*)
  exec /usr/share/omarchy/bin/omarchy-agent ${inline:+--inline} ${pick:+--pick} ${prompt:+--prompt "$prompt"}
  ;;
esac

if [[ $inline == "true" ]]; then
  exec "${command[@]}"
else
  exec omarchy-launch-tui --app-id=org.omarchy.agent "${command[@]}"
fi
INNER_EOF
chmod +x "$HOME/.local/bin/omarchy-agent"

# 5. Create compatibility gemini shim
cat << 'INNER_EOF' > "$HOME/.local/bin/gemini"
#!/bin/bash
# Shim translating legacy gemini CLI calls to agy
args=()
while (($#)); do
  case "$1" in
    --yolo)
      args+=(--dangerously-skip-permissions)
      shift
      ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done

exec agy "${args[@]}"
INNER_EOF
chmod +x "$HOME/.local/bin/gemini"

# 6. Remove stale gemini package from mise if present
if command -v mise &>/dev/null; then
  mise uninstall gemini 2>/dev/null || true
  mise prune -y 2>/dev/null || true
  if [[ -f "$HOME/.config/mise/config.toml" ]]; then
    sed -i '/gemini/d' "$HOME/.config/mise/config.toml" 2>/dev/null || true
  fi
  mise reshim 2>/dev/null || true
fi

# 7. Configure Omarchy default agent to agy
echo "agy" > "$HOME/.config/omarchy/defaults/agent"

# 8. Add Antigravity entry to Omarchy menu extension
MENU_EXT="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
if [[ ! -f "$MENU_EXT" ]]; then
  cat << 'INNER_EOF' > "$MENU_EXT"
{
  "setup.default.agent.agy": {
    "icon": "󰚩",
    "label": "Antigravity (agy)",
    "checked": "[[ \"$(omarchy-default-agent)\" == \"agy\" ]]",
    "action": "omarchy-default-agent agy"
  },
  "setup.default.agent.gemini": {
    "icon": "󰫢",
    "label": "Gemini (mapped to agy)",
    "checked": "[[ \"$(omarchy-default-agent)\" == \"gemini\" || \"$(omarchy-default-agent)\" == \"agy\" ]]",
    "action": "omarchy-default-agent agy"
  }
}
INNER_EOF
else
  # If file exists and doesn't mention agy, merge or instruct
  if ! grep -q "setup.default.agent.agy" "$MENU_EXT"; then
    echo "ℹ️  Updating $MENU_EXT with Antigravity menu items..."
    sed -i 's/}/  "setup.default.agent.agy": {"icon":"󰚩","label":"Antigravity (agy)","checked":"[[ \\"$(omarchy-default-agent)\\" == \\"agy\\" ]]","action":"omarchy-default-agent agy"},\n  "setup.default.agent.gemini": {"icon":"󰫢","label":"Gemini (mapped to agy)","checked":"[[ \\"$(omarchy-default-agent)\\" == \\"gemini\\" || \\"$(omarchy-default-agent)\\" == \\"agy\\" ]]","action":"omarchy-default-agent agy"}\n}/' "$MENU_EXT" 2>/dev/null || true
  fi
fi

# 9. Configure Hyprland keybindings
HYPR_BINDINGS="$HOME/.config/hypr/bindings.lua"
if [[ -f "$HYPR_BINDINGS" ]]; then
  if ! grep -q "Agent (Antigravity)" "$HYPR_BINDINGS"; then
    cat << 'INNER_EOF' >> "$HYPR_BINDINGS"

-- Ensure Super+Shift+A and Super+Shift+Ctrl+A launch Antigravity (agy)
hl.unbind("SUPER + SHIFT + A")
hl.unbind("SUPER + SHIFT + CTRL + A")

o.bind("SUPER + SHIFT + A", "Agent (Antigravity)", "omarchy-launch-tui --app-id=org.omarchy.agent agy --dangerously-skip-permissions")
o.bind("SUPER + SHIFT + CTRL + A", "Agent (Antigravity)", "omarchy-launch-tui --app-id=org.omarchy.agent agy --dangerously-skip-permissions")
INNER_EOF
  fi
fi

# 10. Ensure Hyprland PATH includes ~/.local/bin
HYPR_MAIN="$HOME/.config/hypr/hyprland.lua"
if [[ -f "$HYPR_MAIN" ]] && ! grep -q "hl.env(\"PATH\"" "$HYPR_MAIN"; then
  cat << 'INNER_EOF' >> "$HYPR_MAIN"

-- Ensure user local bin is prioritized in Hyprland
hl.env("PATH", (os.getenv("HOME") or "/home/zehd") .. "/.local/bin:" .. (os.getenv("PATH") or ""))
INNER_EOF
fi

# 11. Reload Hyprland if active
if command -v hyprctl &>/dev/null; then
  hyprctl reload 2>/dev/null || true
fi

echo "✅ Antigravity setup completed successfully!"
echo "   Default agent: $(omarchy-default-agent)"
echo "   Keybindings: Super+Shift+A and Super+Shift+Ctrl+A"
