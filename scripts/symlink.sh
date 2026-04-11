#!/bin/bash
# symlink.sh <source_dir> <target_dir>
# Recursively links files from source_dir into target_dir.
# Designed for deep layering: it forcefully overwrites existing symlinks,
# allowing later layers (e.g., overrides) to dominate earlier layers.

SRC_DIR="$1"
TARGET_DIR="$2"

if [ -z "$SRC_DIR" ] || [ -z "$TARGET_DIR" ]; then
    echo "Usage: $0 <source_dir> <target_dir>"
    exit 1
fi

if [ ! -d "$SRC_DIR" ]; then
    # Silently skip if a particular layer directory isn't fully populated yet
    exit 0
fi

SRC_ABS="$(cd "$SRC_DIR" && pwd)"

cd "$SRC_ABS" || exit 1
find . -type f | while IFS= read -r file; do
    # Strip leading ./
    rel_path="${file#./}"
    
    src_file_path="$SRC_ABS/$rel_path"
    target_file_path="$TARGET_DIR/$rel_path"
    target_dir_path=$(dirname "$target_file_path")
    
    # Ensure the parent directory exists in target
    mkdir -p "$target_dir_path"
    
    # If the target exists and is NOT a symlink, back it up to prevent data loss
    if [ -e "$target_file_path" ] && [ ! -L "$target_file_path" ]; then
        echo "💾 Backing up existing file: $target_file_path to $target_file_path.bak"
        mv "$target_file_path" "$target_file_path.bak"
    fi
    
    # Create the symlink, overwriting (-f) any existing symlink from earlier layers
    ln -sf "$src_file_path" "$target_file_path"
    # echo "🔗 Linked: $target_file_path -> $src_file_path"
done
