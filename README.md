# Synology USB device script

A script to mount or eject an USB device from a Synology NAS.

## What it is for

This script should be used on a Synology NAS to unmount USB devices periodically. This can be useful if a daily 
backup is created on the USB device.

## What it does

- Use `df` to determine mounted USB devices
- Eject the first device (this script assumes that only one device is connected)
- Power the device down
- Write the device id to `/volume1/scripts/usb-info` to mount the device later
- Mount the device

## Usage

```
./usb-device.sh mount|eject
```

## Deployment

The `deploy.sh` script helps to deploy the script on the Synology NAS. Then run the script by providing the host 
name of the Synology NAS:

```
./deploy.sh <user>@<host>
```

The script will ask for the password of the user twice.

### Preconditions for deployment

- SSH must be enabled
- The shared folder `/volume1/scripts` must exist

## Setup scheduled tasks

In the Synology Control Panel create two scheduled tasks. Let's assume your backup task runs every day at 1:00. Then 
the first scheduled task to mount the USB device should run some time earlier, e.g. at 0:00. Then you have to 
consider that sometimes a backup integrity check runs. You can see the duration of the backup task and the backup 
integrity check in the log output of your Synology NAS. I recommend to run the eject task 2 to 3 hours after the 
backup integrity check. The schedule could look like this:

- 0:00 - mount usb task
- 1:00 - backup task
- 3:00 - backup integrity check task
- 6:00 - eject usb task

The tasks should run under the `root` user.

The script for the mount usb task is:

```
bash /volume1/scripts/usb-device.sh mount
```

The script for the eject usb task is:

```
bash /volume1/scripts/usb-device.sh eject
```