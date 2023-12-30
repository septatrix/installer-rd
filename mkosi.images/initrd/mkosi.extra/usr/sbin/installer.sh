#!/usr/bin/bash

set -eu -o pipefail

dmesg --console-off
echo
cat <<EOF
                                    ███    ███
 █████                  █             █      █
   █                    █             █      █
   █    █▒██▒  ▒███▒  █████  ░███░    █      █     ███    █▒██▒
   █    █▓ ▒█  █▒ ░█    █    █▒ ▒█    █      █    ▓▓ ▒█   ██  █
   █    █   █  █▒░      █        █    █      █    █   █   █
   █    █   █  ░███▒    █    ▒████    █      █    █████   █
   █    █   █     ▒█    █    █▒  █    █      █    █       █
   █    █   █  █░ ▒█    █░   █░ ▓█    █░     █░   ▓▓  █   █
 █████  █   █  ▒███▒    ▒██  ▒██▒█    ▒██    ▒██   ███▒   █
EOF

echo
echo
echo
echo "Searching for hard drives ..."
sleep .5

# Exclude loop and CD-ROM devices
block_devices="$(lsblk --noheadings --nodeps --exclude 7,11 --output NAME)"

available_targets=""
for device in $block_devices; do
    case $device in
        ram*|zram*)
            # skip ram device
            ;;
        *)
            available_targets="$available_targets $device"
            ;;
    esac
done


if [[ ! $available_targets ]]; then
    echo "No installation targets found. Installation aborted."
    # sleep and poweroff
    exit 1
fi

# Display found drives and their basic info
# shellcheck disable=SC2046,SC2086
lsblk -o NAME,SIZE,VENDOR,MODEL,SERIAL --nodeps $(printf "/dev/%s " $available_targets)

# Get user choice
while [[ ! -v install_target ]]; do
    echo "Please select an install target or type 'n' to exit ($available_targets ): "
    read -r answer
    if [[ $answer = n ]]; then
        echo "Installation manually aborted."
        # sleep and poweroff
        exit 1
    fi
    for target in $available_targets; do
        if [[ $answer = "$target" ]]; then
            install_target=$target
            break
        fi
    done
done

echo "Installing image on /dev/$install_target ..."
echo "This might take a while..."

cp /sysroot/image "/dev/$install_target" & progress --monitor --pid $! && wait -n
sync
parted --script --fix "/dev/$install_target" unit MiB print

echo "Installation successful. Remove your installation media and then press ENTER."
read -r
echo "Rebooting..."
