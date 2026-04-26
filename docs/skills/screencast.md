# 🎥 Skill: Integrated Screencasting

This skill enables the automated generation of professional documentation GIFs with zero post-processing. It integrates cursor tracking, click visualization, and window-aware recording into a single command.

## Core Tool: `create_demo.sh`

Located at: `scripts/create_demo.sh`

### Basic Usage
```bash
# Record for 5 seconds (default region)
./scripts/create_demo.sh --name my_feature

# Select a specific window to record
./scripts/create_demo.sh --select --name terminal_demo

# Add a text overlay for button indicators
./scripts/create_demo.sh --text "SUPER + ALT + S" --name sticky_note_demo
```

### Automation & Simulations
You can pass a simulation script to ensure the demonstration is reproducible and perfectly timed:

```bash
./scripts/create_demo.sh --name move_demo --sim "xdotool keydown Super_L; xdotool mousemove 500 500; xdotool mousedown 1; xdotool mousemove 1000 500; xdotool mouseup 1; xdotool keyup Super_L"
```

### Visual Enhancements
- **Cursor Halo**: Enabled by default. Creates a yellow highlight following the mouse. Use `--no-halo` to disable.
- **Overlays**: Use `--text "..."` to add a high-contrast label at the bottom of the GIF.

---

## 🔌 Agent (AI) Integration

This tool is specifically refined for autonomous usage by AI agents (like Antigravity).

### Autonomous Commands
When requested to "record a demo," the agent should use the following pattern:
```bash
# Non-interactive window recording
./scripts/create_demo.sh --window "Kitty" --name autonomous_demo --json
```

### Key AI Flags
- `--window <search>`: Targets a window by ID or Title. Removes the need for user clicks.
- `--json`: Outputs structured data, allowing the agent to confirm the GIF path and embed it immediately in the conversation.
- `--preset <center|split>`: Optimized coordinates for ultra-wide setups.

---

> [!IMPORTANT]
> **Dependencies**: Ensure `ffmpeg`, `xdotool`, and `xwininfo` are installed (handled by `os/ubuntu/install.sh`).
