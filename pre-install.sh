#!/bin/sh


# === IMPORTANT ===
# Before running the script make sure you have internet connection


# Set up required variables
# If any of the required variables is not set the installation will not start
# e.g. drive=/dev/sda
drive=

# e.g. boot_part=$drive1 || boot_part=/dev/sda1
boot_part=
swap_part=
home_part=
root_part=

# e.g. boot_part_size=550MiB || home_part_size=10GiB
boot_part_size=
swap_part_size=
home_part_size=


# The function checks if a variable is set.
# If the variable is not set, the function will exit.
#
#   :param $1: string of the variable which needs to be set
#   :param $1: variable to be checked
is_set() {
    [[ -z "$2" ]] && { echo "Error: $1 is not set"; exit 1; } || echo "$1: $2"
}

check() {
    is_set "drive"          $drive
    is_set "boot_part"      $boot_part
    is_set "swap_part"      $swap_part
    is_set "home_part"      $home_part
    is_set "root_part"      $root_part
    is_set "boot_part_size" $boot_part_size
    is_set "swap_part_size" $swap_part_size
    is_set "home_part_size" $home_part_size
}

partition_drive() {
    echo "start partitioning..."

    echo "wiping drive $drive..."
    sgdisk --zap-all $drive

    echo "create partitions..."
    sgdisk --clear \
        --new=1:0:+${boot_part_size}    --typecode=1:ef00 \
        --new=2:0:+${swap_part_size}    --typecode=2:8200 \
        --new=3:0:+${home_part_size}    --typecode=3:8300 \
        --largest-new=4                 --typecode=4:8300 \
        $drive
}

format_drive() {
    echo "start formatting..."

    echo "format boot partition..."
    mkfs.fat -F32 $boot_part

    echo "create swap partition..."
    mkswap $swap_part

    echo "create home partition"
    mkfs.ext4 -F $home_part

    echo "create root partition"
    mkfs.ext4 -F $root_part
}

mount_drive() {
    echo "mount partitions..."

    echo "mount root partition..."
    mount $root_part /mnt

    echo "mount boot partition..."
    mkdir /mnt/boot
    mount $boot_part /mnt/boot

    echo "mount home partition..."
    mkdir /mnt/home
    mount $home_part /mnt/home

    echo "mount swap partition..."
    swapon $swap_part
}

install_system() {
    pacman -Sy
    pacman -S --noconfirm reflector

    # Use reflector for faster installtion
    /usr/bin/reflector --protocol https --latest 30 --number 20 --sort rate --save /etc/pacman.d/mirrorlist

    pacstrap /mnt base base-devel linux linux-firmware

    genfstab -U /mnt > /mnt/etc/fstab

    cp ./pre-install.sh /mnt
    cp ./post-install.sh /mnt
    cp -r ./misc /mnt
}


full_install() {
    check

    partition_drive
    format_drive
    mount_drive
    install_system

    # After installation chroot to the new system and run post-install.sh script
}


case $1 in
    "check")
        check
        ;;
    "partition")
        partition_drive
        ;;
    "format")
        format_drive
        ;;
    "mount")
        mount_drive
        ;;
    "install")
        install_system
        ;;
    "full")
        full_install
        ;;
    *)
        echo "Unknown option: ${1}"
esac
