#!/bin/bash

NAS_HOST=${1:?Usage: $0 <nas-host>}
DEPLOY_DIR=/volume1/scripts

scp -O src/usb-device.sh "$NAS_HOST:$DEPLOY_DIR/"
ssh "$NAS_HOST" "chmod +x $DEPLOY_DIR/usb-device.sh"
