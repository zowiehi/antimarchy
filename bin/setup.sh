#!/usr/bin/env bash
set -euo pipefail

echo "========================================================"
echo "  Antimarchy: Antigravity (agy) Integration for Omarchy"
echo "========================================================"

# Interactive consent check
if [[ "${1:-}" != "-y" && "${1:-}" != "--yes" ]]; then
  echo ""
  echo "This setup script will:"
  echo "  1. Install 'antigravity-cli' via AUR (yay/paru) if missing"
  echo "  2. Configure Antigravity as your Omarchy default agent"
  echo "  3. Dynamically configure Omarchy menu to place Antigravity at the top"
  echo "  4. Add Super+Shift+A & Super+Shift+Ctrl+A hotkeys to ~/.config/hypr/bindings.lua"
  echo "  5. Clean up deprecated Gemini CLI package references in Mise"
  echo "  (Automatic backups of any modified files will be created)"
  echo ""
  read -r -p "Do you want to proceed with this configuration? [y/N] " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Setup cancelled by user."
    exit 0
  fi
fi

echo "==> Configuring Antigravity (agy) integration..."

backup_file() {
  local f="$1"
  if [[ -f "$f" ]]; then
    cp "$f" "${f}.bak.$(date +%Y%m%d%H%M%S)"
  fi
}

# 1. Install agy if missing
if ! command -v agy &>/dev/null; then
  echo "==> Antigravity CLI ('agy') not found. Installing via AUR..."
  if command -v yay &>/dev/null; then
    yay -S --needed --noconfirm antigravity-cli
  elif command -v paru &>/dev/null; then
    paru -S --needed --noconfirm antigravity-cli
  else
    echo "⚠️  Neither yay nor paru found. Please install 'antigravity-cli' manually."
  fi
fi

# 2. Ensure directories exist
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
  if ! command -v agy &>/dev/null; then
    if [[ $installing == "false" ]]; then
      exec omarchy-launch-floating-terminal-with-presentation omarchy-default-agent --install "agy"
    else
      echo "==> Installing Google Antigravity (antigravity-cli)..."
      if command -v yay &>/dev/null; then
        yay -S --needed antigravity-cli
      elif command -v paru &>/dev/null; then
        paru -S --needed antigravity-cli
      else
        echo "Could not find yay/paru to install antigravity-cli from AUR." >&2
        exit 1
      fi
    fi
  fi

  mkdir -p "$(dirname "$agent_file")"
  printf '%s\n' "agy" >"$agent_file"
  echo "Default coding agent set to Antigravity (agy)"

  if [[ $installing == "true" ]]; then
    printf '\033[2J\033[3J\033[H'
    exec omarchy-agent --inline
  fi
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

# 8. Dynamically construct menu configuration by inspecting the upstream system menu
MENU_EXT="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
backup_file "$MENU_EXT"

node - << 'NODE_EOF'
const fs = require('fs');
const omarchyPath = process.env.OMARCHY_PATH || '/usr/share/omarchy';
const defaultMenuFile = `${omarchyPath}/default/omarchy/omarchy-menu.jsonc`;
const userMenuFile = process.env.HOME + '/.config/omarchy/extensions/omarchy-menu.jsonc';

let defaultMenu = {};
if (fs.existsSync(defaultMenuFile)) {
  try {
    const raw = fs.readFileSync(defaultMenuFile, 'utf8')
      .replace(/^\s*\/\/[^\n]*(\n|$)/gm, '')
      .replace(/,(\s*[}\]])/g, '$1');
    defaultMenu = JSON.parse(raw);
  } catch (e) {
    console.error("Error reading default menu:", e);
  }
}

// 1. Discover all agent slots in order from the system menu
const agentSlots = Object.keys(defaultMenu)
  .filter(id => id.startsWith('setup.default.agent.') && id.split('.').length === 4);

// 2. Extract active upstream agent definitions (excluding deprecated gemini)
const upstreamAgents = agentSlots
  .filter(id => id !== 'setup.default.agent.gemini')
  .map(id => defaultMenu[id]);

// 3. Define Antigravity top entry
const agyEntry = {
  icon: "󰚩",
  iconFont: "",
  label: "Antigravity",
  checked: '[[ "$(omarchy-default-agent)" == "agy" ]]',
  action: "omarchy-default-agent agy"
};

// 4. Combine: Antigravity first, followed dynamically by all discovered upstream agents
const allAgents = [agyEntry, ...upstreamAgents];
const dynamicMapping = {};

// 5. Dynamically assign each agent to the available slots in exact order
allAgents.forEach((agent, index) => {
  const slotId = agentSlots[index] || `setup.default.agent.custom_${index}`;
  dynamicMapping[slotId] = Object.assign({}, agent);
});

// 6. Non-destructively merge with existing user menu extensions
let userExisting = {};
if (fs.existsSync(userMenuFile)) {
  try {
    const rawUser = fs.readFileSync(userMenuFile, 'utf8')
      .replace(/^\s*\/\/[^\n]*(\n|$)/gm, '')
      .replace(/,(\s*[}\]])/g, '$1');
    userExisting = JSON.parse(rawUser);
  } catch (e) {}
}

const finalMerged = Object.assign({}, userExisting, dynamicMapping);
fs.writeFileSync(userMenuFile, JSON.stringify(finalMerged, null, 2) + '\n');
console.log("==> Dynamically loaded and mapped", allAgents.length, "agents into Omarchy menu.");
NODE_EOF

# 9. Configure Hyprland keybindings (non-destructive append)
HYPR_BINDINGS="$HOME/.config/hypr/bindings.lua"
if [[ -f "$HYPR_BINDINGS" ]]; then
  backup_file "$HYPR_BINDINGS"
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
  backup_file "$HYPR_MAIN"
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
