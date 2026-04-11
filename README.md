# Multi-System Config Architecture

A modular, highly composable dotfiles repository designed for cross-OS and cross-WM reproducible environments.

## Features

- **Layered Architecture**: Automatically resolves configs from `base` -> `os` -> `wm` -> `modules` -> `hosts` -> `overrides`.
- **Modular Apps**: Enable or disable terminal, compositor, web browsers natively simply by removing the directory in `modules/`.
- **Safe Linking**: A custom `symlink.sh` engine handles creating symlinks across environments and safely backs up existing real files.

## Documentation

- [Architecture Design](docs/architecture.md)

## Quick Start

1. Review what modules you want to install. All modules found in `modules/*/*` are installed by default.
2. Run `make` specifying your exact target:

```bash
# Example: Install dotfiles for Arch Linux utilizing i3
make all OS=arch WM=i3 

# Example: Install dotfiles for Ubuntu utilizing bspwm, with a specific hostname override
make all OS=ubuntu WM=bspwm HOST=my-laptop-name
```
