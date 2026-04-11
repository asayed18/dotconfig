# Dotconfig Architecture

This dotfiles repository uses a heavily modularised, multi-layered directory structure to facilitate full system reproducible state across different Operating Systems (Ubuntu, Arch, etc.) and Desktop Environments (i3, bspwm, Openbox, etc.).

## The Tree Model

Configurations are stored in the following hierarchical layers logically distributed by scope:

1. **`base/`**: Universal POSIX defaults and shared system configurations (`.zshrc`, `.bashrc`).
2. **`os/`**: OS-specific components (`apt` vs `pacman` installers, OS-specific quirks).
3. **`wm/`**: Window Managers & DEs (`i3`, `bspwm`, `openbox`).
4. **`modules/`**: Reusable apps and features (`kitty`, `rofi`, `polybar`).
5. **`hosts/`**: Machine-specific configurations mapped by hostnames (e.g., specific monitor orientations).
6. **`overrides/`**: Temporary or highly specific user-level overrides.

## Resolution Order

The Makefile applies these layers in sequence from 1 to 6. Later layers forcefully overwrite earlier layers in the target home directory.
If `modules/terminal/kitty/.config/kitty/kitty.conf` exists, but `overrides/.config/kitty/kitty.conf` also exists, the overriding file will win via our symlink overwriter scripts.

## Installation Flow

The core workflow is driven by `make`:

```bash
make all OS=arch WM=bspwm HOST=laptop
```

This recursively finds all files inside the active layers (base, os/arch, wm/bspwm, modules/*, hosts/laptop, overrides) and creates symbolic links into your `$HOME` directory.

- If a real file exists at the target path, it is automatically backed up (e.g. `file.bak`).
- If a symlink exists, it is overwritten, which facilitates the layer overriding.
