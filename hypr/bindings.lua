-- Hyprland bindings for Antigravity AI Agent in Omarchy
hl.unbind("SUPER + SHIFT + A")
hl.unbind("SUPER + SHIFT + CTRL + A")

o.bind("SUPER + SHIFT + A", "Agent (Antigravity)", "omarchy-launch-tui --app-id=org.omarchy.agent agy --dangerously-skip-permissions")
o.bind("SUPER + SHIFT + CTRL + A", "Agent (Antigravity)", "omarchy-launch-tui --app-id=org.omarchy.agent agy --dangerously-skip-permissions")
