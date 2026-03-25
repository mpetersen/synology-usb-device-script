#!/bin/bash

USB_INFO_FILE=/volume1/scripts/usb-info

case "$1" in
    eject)
        # Find USB device and mount path, store both for remounting later
        df | awk '/\/volumeUSB/ {print $1, $6}' > "$USB_INFO_FILE"

        USB_DEV=$(awk '{print $1}' "$USB_INFO_FILE")
        MOUNT_PATH=$(awk '{print $2}' "$USB_INFO_FILE")

        if [ -z "$MOUNT_PATH" ]; then
            echo "No USB device mounted."
            exit 0
        fi

        umount "$MOUNT_PATH"
        ;;
    mount)
        USB_DEV=$(awk '{print $1}' "$USB_INFO_FILE")
        MOUNT_PATH=$(awk '{print $2}' "$USB_INFO_FILE")

        if [ -z "$USB_DEV" ]; then
            echo "No USB info found. Run eject first."
            exit 1
        fi

        mount "$USB_DEV" "$MOUNT_PATH"
        ;;
    *)
        echo "Usage: $0 {eject|mount}"
        exit 1
        ;;
esac
