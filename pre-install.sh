#!/bin/sh


init() {
    echo "Set up required variables..."

    read -p "Select drive: " DRIVE_ID
    DRIVE=/dev/${DRIVE_ID}

    BOOT_PART=${DRIVE}1
    SWAP_PART=${DRIVE}2
    HOME_PART=${DRIVE}3
    ROOT_PART=${DRIVE}4

    echo "Set size of form nMiB (e.g. 550MiB, 4GiB)"
    read -p "Set boot partition size: " BOOT_PART_SIZE
    read -p "Set swap partition size: " SWAP_PART_SIZE
    read -p "Set home partition size: " HOME_PART_SIZE

    echo "Partition drive: ${DRIVE}"
    echo "Boot partition: ${BOOT_PART}, of size: ${BOOT_PART_SIZE}"
    echo "Swap partition: ${SWAP_PART}, of size: ${SWAP_PART_SIZE}"
    echo "Home partition: ${HOME_PART}, of size: ${HOME_PART_SIZE}"
    echo "Root partition: ${ROOT_PART}, of size whatever's left"
}

partition_drive() {
    echo "Start partitioning..."

    echo "Wiping drive $DRIVE..."
    sgdisk --zap-all $DRIVE

    echo "Create partitions..."
    sgdisk --clear \
        --new=1:0:+${BOOT_PART_SIZE}    --typecode=1:ef00 \
        --new=2:0:+${SWAP_PART_SIZE}    --typecode=2:8200 \
        --new=3:0:+${HOME_PART_SIZE}    --typecode=3:8300 \
        --largest-new=4                 --typecode=4:8300 \
        $DRIVE
}

format_drive() {
    echo "Start formatting..."

    echo "Format boot partition..."
    mkfs.fat -F32 $BOOT_PART

    echo "Create swap partition..."
    mkswap $SWAP_PART

    echo "Create home partition"
    mkfs.ext4 $HOME_PART

    echo "Create root partition"
    mkfs.ext4 $ROOT_PART
}

mount_drive() {
    echo "Mount partitions..."

    echo "Mount root partition..."
    mount $ROOT_PART /mnt

    echo "Mount boot partition..."
    mkdir /mnt/boot
    mount $BOOT_PART /mnt/boot

    echo "Mount home partition..."
    mkdir /mnt/home
    mount $HOME_PART /mnt/home

    echo "Mount swap partition..."
    swapon $SWAP_PART
}

install_system() {
    # Use reflector for faster installtion
    pacman -Sy
    pacman -S --noconfirm reflector

    /usr/bin/reflector --protocol https --latest 30 --number 20 --sort rate --save /etc/pacman.d/mirrorlist

    pacstrap /mnt base base-devel linux linux-firmware networkmanager wpa_supplicant vim

    genfstab -U /mnt > /mnt/etc/fstab

    cp ./post-install.sh /mnt
    cp -r ./misc /mnt
}


case $1 in
    "init")
        init
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
    *)
        echo "Unknown option: ${1}"
esac
