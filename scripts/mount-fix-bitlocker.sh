#!/bin/bash
# scripts/mount-fix-bitlocker.sh
# A helper script to detect and repair "dirty" BitLocker-decrypted partitions

# 1. Detect any active BitLocker mappers
MAPPERS=$(ls /dev/mapper/bitlk-* 2>/dev/null)

if [ -z "$MAPPERS" ]; then
    echo "❌ No active BitLocker mappings found in /dev/mapper/."
    echo "Make sure you have unlocked the drive first (e.g. via your file manager)."
    exit 1
fi

echo "🔍 Found the following decrypted partitions:"
select MAPPER in $MAPPERS; do
    if [ -n "$MAPPER" ]; then
        echo "🛠️ Analyzing $MAPPER..."
        
        # Check if it's already mounted
        if mount | grep -q "$MAPPER"; then
            echo "✅ $MAPPER is already mounted."
            exit 0
        fi

        echo "⚠️ This partition is likely 'dirty' due to Windows Fast Startup."
        echo "Choice:"
        echo "1) Run ntfsfix (Removes the dirty flag)"
        echo "2) Try to mount read-only"
        echo "3) Cancel"
        
        read -p "Select an action [1-3]: " ACTION
        
        case $ACTION in
            1)
                echo "🚀 Running sudo ntfsfix $MAPPER..."
                sudo ntfsfix "$MAPPER"
                echo "✅ Done. Try mounting it again from your file manager."
                ;;
            2)
                MOUNT_POINT="/media/$USER/bin-recovered"
                sudo mkdir -p "$MOUNT_POINT"
                echo "🚀 Mounting read-only to $MOUNT_POINT..."
                sudo mount -t ntfs -o ro "$MAPPER" "$MOUNT_POINT"
                echo "✅ Mounted at $MOUNT_POINT"
                ;;
            *)
                echo "Cancelled."
                ;;
        esac
        break
    else
        echo "Invalid selection."
    fi
done
