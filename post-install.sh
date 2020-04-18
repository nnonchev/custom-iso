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

    pacman -S --noconfirm grub efibootmgr

    grub-install --target=x86_64-efi --efi-directory="${esp}" --bootloader-id=GRUB
    grub-mkconfig -o "${esp}/grub/grub.cfg"

    # TODO Is it really needed???
    pacman -S --noconfirm intel-ucode
    grub-mkconfig -o "${esp}/grub/grub.cfg"
}

allow_wheel() {
    echo "Allow wheel group users to use sudo..."

    sed -i "s/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/" /etc/sudoers
}

add_user() {
    echo "Adding user..."
    useradd -m -G wheel,video -s /bin/bash $username
}

install_xorg() {
    echo "Installing xorg..."
    pacman -S --noconfirm xorg xorg-xinit

    touch /home/$username/{.xinitrc,.xprofile}
    echo "[ -f /home/$username/.xprofile ] && . /home/$username/.xprofile" > /home/$username/.xinitrc
    echo "" >> /home/$username/.xinitrc

    mkdir /home/$username/.config

    chown $username:$username /home/$username/.xinitrc
    chown $username:$username /home/$username/.xprofile
    chown $username:$username /home/$username/.config
}

install_nvidia() {
    echo "Installing nvidia..."
    pacman -S --noconfirm nvidia
}

install_network_manager() {
    echo "Installing network manager..."
    pacman -S --noconfirm wpa_supplicant networkmanager

    systemctl enable NetworkManager
}

set_reflector() {
    echo "Configure reflector service..."
    cp misc/reflector.service /etc/systemd/system/

    systemctl enable reflector.service
}

# TODO Not verified
install_gnome() {
    echo "Installing gnome..."
    pacman -S --noconfirm gnome gnome-tweaks
}

# TODO Not verified
install_kde() {
    pacman -S --noconfirm plasma kde-applications
    systemctl enable sddm

    echo "exec startplasma-x11" >> /home/${username}/.xinitrc
}

install_awesome() {
    pacman -S --noconfirm awesome

    mkdir -p /home/${username}/.config/awesome
    cp /etc/xdg/awesome/rc.lua /home/${username}/.config/awesome/
    echo "exec awesome" >> /home/${username}/.xinitrc

    chown ${username}:${username} /home/${username}/.xinitrc
    chown -R ${username}:${username} /home/${username}/.config

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

install_ide() {
    pacman -S --noconfirm vi vim neovim
}

install_browser() {
    pacman -S --noconfirm firefox-developer-edition chromium
}

# Move pre-install.sh, post-install.sh scripts, and misc folder to the home folder of the user
# This will allow the user to examine exactly how the system has been installed and which files have been transfered
clean() {
    mkdir /home/$username/installation
    mv pre-install.sh /home/$username/installation
    mv post-install.sh /home/$username/installation
    mv misc /home/$username/installation

    chown $username:$username -R /home/$username/installation
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
    install_nvidia
    install_network_manager
    set_reflector
    install_awesome
    install_gdm
    install_terminal
    install_shell
    install_browser

    clean
}


case $1 in
    "check")            check ;;
    "timedate")         set_timedate ;;
    "timezone")         set_timezone ;;
    "locale")           set_locale ;;
    "hostname")         set_hostname ;;
    "bootloader")       set_bootloader_efi ;;
    "wheel")            allow_wheel ;;
    "user")             add_user ;;
    "xorg")             install_xorg ;;
    "nvidia")           install_nvidia ;;
    "network-manager")  install_network_manager ;;
    "reflector")        set_reflector ;;
    "gnome")            install_gnome ;;
    "kde")              install_kde ;;
    "awesome")          install_awesome ;;
    "gdm")              install_gdm ;;
    "terminal")         install_terminal ;;
    "shell")            install_shell ;;
    "ide")              install_ide ;;
    "browser")          install_browser ;;
    "clean")            clean ;;
    "full")             full_install ;;
    *)                  echo "Unknown option: ${1}"
esac
