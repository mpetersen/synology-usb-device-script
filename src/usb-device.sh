#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USB_INFO_FILE="$SCRIPT_DIR/usb-info"

# Step 1: detect any currently mounted USB device
CURRENT_USB=$(df | awk '/\/volumeUSB/ {print $1, $6}')

# Step 2: if a USB device is mounted, update usb-info; otherwise leave it untouched
if [ -n "$CURRENT_USB" ]; then
    echo "$CURRENT_USB" > "$USB_INFO_FILE"
fi

# Step 3: read stored info and process command
USB_DEV=$(awk '{print $1}' "$USB_INFO_FILE" 2>/dev/null)
MOUNT_PATH=$(awk '{print $2}' "$USB_INFO_FILE" 2>/dev/null)

case "$1" in
    eject)
        if [ -z "$CURRENT_USB" ]; then
            echo "No USB device mounted."
            exit 0
        fi

        umount "$MOUNT_PATH"
        ;;
    mount)
        if [ -z "$USB_DEV" ]; then
            echo "No USB info found. Run eject first."
            exit 1
        fi

        if [ -n "$CURRENT_USB" ]; then
            echo "USB device is already mounted at $MOUNT_PATH."
            exit 0
        fi

        mount "$USB_DEV" "$MOUNT_PATH"
        ;;
    *)
        echo "Usage: $0 {eject|mount}"
        exit 1
        ;;
esac
