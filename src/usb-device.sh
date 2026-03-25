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

        # Figure out if a process may be using the device
        for pid_dir in /proc/[0-9]*/; do
            pid="${pid_dir//[^0-9]/}"
            cwd=$(readlink "${pid_dir}cwd" 2>/dev/null)
            if [[ "$cwd" == "$MOUNT_PATH"* ]]; then
                echo "Cannot eject: process $(cat ${pid_dir}comm 2>/dev/null) (PID $pid) is using $MOUNT_PATH"
                exit 1
            fi
            for fd in "${pid_dir}fd/"*; do
                target=$(readlink "$fd" 2>/dev/null)
                if [[ "$target" == "$MOUNT_PATH"* ]]; then
                    echo "Cannot eject: process $(cat ${pid_dir}comm 2>/dev/null) (PID $pid) has open files on $MOUNT_PATH"
                    exit 1
                fi
            done
        done
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
