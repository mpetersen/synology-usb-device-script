#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USB_INFO_FILE="$SCRIPT_DIR/usb-info"
CURRENT_USB=$(df | awk '/\/volumeUSB/ {print $1, $6}')

case "$1" in
    eject)
        if [ -z "$CURRENT_USB" ]; then
            echo "No USB device mounted."
            exit 0
        fi

        USB_DEV=$(echo "$CURRENT_USB" | awk '{print $1}')
        MOUNT_PATH=$(echo "$CURRENT_USB" | awk '{print $2}')

        # Check for processes using the mount point
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

        # Derive USB device ID from udevadm path (e.g. "2-3" from ".../usb2/2-3/2-3:1.0/...")
        UDEV_PATH=$(udevadm info --name "$USB_DEV" -q path)
        USB_PORT=$(echo "$UDEV_PATH" | awk -F'/' '{for(i=1;i<=NF;i++) if($i ~ /^[0-9]+-[0-9]+$/) {print $i; exit}}')
        if [ -z "$USB_PORT" ]; then
            echo "Could not determine USB device port from udevadm."
            exit 1
        fi

        umount "$MOUNT_PATH"
        echo "$USB_PORT" > "$USB_INFO_FILE"
        echo "$USB_PORT" | tee /sys/bus/usb/drivers/usb/unbind > /dev/null
        ;;
    mount)
        USB_PORT=$(cat "$USB_INFO_FILE" 2>/dev/null)
        if [ -z "$USB_PORT" ]; then
            echo "No USB info found. Run eject first."
            exit 1
        fi

        if [ -n "$CURRENT_USB" ]; then
            MOUNT_PATH=$(echo "$CURRENT_USB" | awk '{print $2}')
            echo "USB device is already mounted at $MOUNT_PATH."
            exit 0
        fi

        echo "$USB_PORT" | tee /sys/bus/usb/drivers/usb/bind > /dev/null
        ;;
    *)
        echo "Usage: $0 {eject|mount}"
        exit 1
        ;;
esac
