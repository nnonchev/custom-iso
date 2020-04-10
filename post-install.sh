#!/bin/sh

# Set up required variables
# If any of the required variables is not set the installation will not start
username=
hostname=
continet=
city=
lang=
esp=


# The function checks if a variable is set.
# If the variable is not set, the function will exit.
#
#   :param $1: string of the variable which needs to be set
#   :param $1: variable to be checked
is_set() {
    [[ -z "$2" ]] && { echo "Error: $1 is not set"; exit 1; } || echo "$1: $2"
}

check() {
    is_set "username"   $username
    is_set "hostname"   $hostname
    is_set "continet"   $continet
    is_set "city"       $city
    is_set "lang"       $lang
    is_set "esp"        $esp
}

set_timedate() {
    echo "Set timedate..."
    timedatectl set-ntp 1
}

set_timezone() {
    echo "Set timezone..."

    ln -sf "/usr/share/zoneinfo/${continet}/${city}" /etc/localtime
    hwclock --systohc
}

set_locale() {
    sed -i "s/#${lang}/${lang}/" /etc/locale.gen
    
    locale-gen
}

set_hostname() {
    echo "Set hostname..."

    echo $hostname > /etc/hostname

    echo "127.0.0.1     localhost" >> /etc/hosts
    echo "::1           localhost" >> /etc/hosts
    echo "127.0.1.1     ${hostname}.localdomain ${hostname}" >> /etc/hosts
}

set_bootloader_efi() {
    echo "Set bootloader (grub EFI)..."

    pacman -S --noconfirm grub efibootmgr intel-ucode

    grub-install --target=x86_64-efi --efi-directory="${esp}" --bootloader-id=grub
    grub-mkconfig -o "${esp}/grub/grub.cfg"
}

allow_wheel() {
    echo "Allow wheel group users to use sudo..."

    sed -i "s/#wheel ALL=(ALL) ALL/wheel ALL=(ALL) ALL/" /etc/locale.gen
}

add_user() {
    echo "Adding user..."
    useradd -m -g wheel,video -s /bin/bash $username
}

install_xorg() {
    echo "Installing xorg..."
    pacman -S --noconfirm xorg xorg-xinit

    touch /home/$username/{.xinitrc,.xprofile}
    echo "[ -f /home/$username/.xprofile ] && . /home/$username/.xprofile" > /home/$username/.xinitrc
    echo "" >> /home/$username/.xinitrc

    chown $username:$username /home/$username/.xinitrc
    chown $username:$username /home/$username/.xprofile
}

install_nvidia() {
    echo "Installing nvidia..."
    pacman -S --noconfirm nvidia
}

install_gnome() {
    echo "Installing gnome..."
    pacman -S --noconfirm gnome gnome-tweaks

    cp -r /misc/.themes /home/$username/

    chown -r $username:$username /home/$username/.themes 
}

install_gdm() {
    echo "Installing gdm..."
    pacman -S --noconfirm gdm
    systemctl enable gdm
}

install_terminal() {
    pacman -S --noconfirm kitty
}

install_shell() {
    pacman -S --noconfirm zsh
    chsh -s /usr/bin/zsh $username
}

install_browser() {
    pacman -S --noconfirm firefox-developer-edition chromium
}

full_install() {
    check
    set_timedate
    set_timezone
    set_locale
    set_hostname
    set_bootloader_efi
    allow_wheel
    add_user
    install_xorg
    install_gnome
    install_gdm
    install_terminal
    install_shell
    install_browser
}


case $1 in
    "check")
        check
        ;;
    "timedate")
        set_timedate
        ;;
    "timezone")
        set_timezone
        ;;
    "locale")
        set_locale
        ;;
    "hostname")
        set_hostname
        ;;
    "hostname")
        set_hostname
        ;;
    "bootloader")
        set_bootloader_efi
        ;;
    "wheel")
        allow_wheel
        ;;
    "user")
        add_user
        ;;
    "xorg")
        install_xorg
        ;;
    "nvidia")
        install_nvidia
        ;;
    "gnome")
        install_gnome
        ;;
    "gdm")
        install_gdm
        ;;
    "terminal")
        install_terminal
        ;;
    "shell")
        install_shell
        ;;
    "browser")
        install_browser
        ;;
    "full")
        full_install
        ;;
    *)
        echo "Unknown option: ${1}"
esac
