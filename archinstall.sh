#!/usr/bin/bash

# Microcode detector (function).
microcode_detector () {
    CPU=$(grep vendor_id /proc/cpuinfo)
    if [[ "$CPU" == *"AuthenticAMD"* ]]; then
        info_print "An AMD CPU has been detected, the AMD microcode will be installed."
        microcode="amd-ucode"
    else
        info_print "An Intel CPU has been detected, the Intel microcode will be installed."
        microcode="intel-ucode"
    fi
}


microcode_detector

UCODE_PKG=$microcode
BTRFS_MOUNT_OPTS="ssd,noatime,compress=zstd:1"

# Localization
# https://wiki.archlinux.org/title/Installation_guide#Localization
LANG='de_DE.UTF-8'
KEYMAP='de-latin1'
# https://wiki.archlinux.org/title/Time_zone
TIMEZONE="Europe/Berlin"

# zram-size option in zram-generator.conf if enabled zram.
ZRAM_SIZE='min(ram / 2, 4 * 1024)'

# minimal example
KERNEL_PKGS="linux"
BASE_PKGS="base sudo linux linux-firmware iptables-nft"
FS_PKGS="dosfstools btrfs-progs e2fsprogs"
OTHER_PKGS="man-db helix micro"
OTHER_PKGS="$OTHER_PKGS git base-devel"

######################################################

echo "

This script is not thoroughly tested. It may wipe all hard drives connected. Make sure you have a working backup.

"
read -p "Press Enter to continue, otherwise press any other key. " start_install

if [[ -n $start_install ]] ; then
    exit 1
fi

echo "
######################################################
# Check internet connection
# https://wiki.archlinux.org/title/Installation_guide#Connect_to_the_internet
######################################################
"
ping -c 1 archlinux.org > /dev/null
if [[ $? -ne 0 ]] ; then
    echo "Please check the internet connection."
    exit 1
else
    echo "Internet OK."
fi


echo "
######################################################
# Update the system clock
# https://wiki.archlinux.org/title/Installation_guide#Update_the_system_clock
######################################################
"
timedatectl set-ntp true

echo "
######################################################
# EFI boot settings
# https://man.archlinux.org/man/efibootmgr.8
######################################################
"
efibootmgr --unicode
efi_boot_id=" "
while [[ -n $efi_boot_id ]]; do
    echo -e "\nDo you want to delete any boot entries?: "
    read -p "Enter boot number (empty to skip): " efi_boot_id
    if [[ -n $efi_boot_id ]] ; then
        efibootmgr --bootnum $efi_boot_id --delete-bootnum --unicode
    fi
done

echo "
######################################################
# Partition disks
# https://wiki.archlinux.org/title/Installation_guide#Partition_the_disks
######################################################
"
umount -R /mnt
devices=$(lsblk --nodeps --paths --list --noheadings --sort=size --output=name,size,model | grep --invert-match "loop" | cat --number)

device_id=" "
while [[ -n $device_id ]]; do
    echo -e "Choose device to format:"
    echo "$devices"
    read -p "Enter a number (empty to skip): " device_id
    if [[ -n $device_id ]] ; then
        device=$(echo "$devices" | awk "\$1 == $device_id { print \$2}")
        fdisk "$device"
    fi
done

partitions=$(lsblk --paths --list --noheadings --output=name,size,model | grep --invert-match "loop" | cat --number)

# EFI partition
echo -e "\n\nTell me the EFI partition number:"
echo "$partitions"
read -p "Enter a number: " efi_id
efi_part=$(echo "$partitions" | awk "\$1 == $efi_id { print \$2}")

# root partition
echo -e "\n\nTell me the root partition number:"
echo "$partitions"
read -p "Enter a number: " root_id
root_part=$(echo "$partitions" | awk "\$1 == $root_id { print \$2}")

# Wipe existing LUKS header
# https://wiki.archlinux.org/title/Dm-crypt/Drive_preparation#Wipe_LUKS_header
# Erase all keys
cryptsetup erase $root_part 2> /dev/null
# Make sure there is no active slots left
cryptsetup luksDump $root_part 2> /dev/null
# Remove LUKS header to prevent cryptsetup from detecting it
wipefs --all $root_part 2> /dev/null

echo "
######################################################
# Format the partitions
# https://wiki.archlinux.org/title/Installation_guide#Format_the_partitions
######################################################
"
# EFI partition
echo "Formatting EFI partition ..."
echo "Running command: mkfs.fat -n boot -F 32 $efi_part"
# create fat32 partition with name(label) boot
mkfs.fat -n boot -F 32 "$efi_part"

# swap partition
if [[ -n $swap_id ]] ; then
    echo "Formatting swap partition ..."
    echo "Running command: mkswap -L swap $swap_part"
    # create swap partition with label swap
    mkswap -L swap "$swap_part"
fi


root_block=$root_part



# format root partition
echo -e "\n\nFormatting root partition ..."
echo "Running command: mkfs.btrfs -L ArchLinux -f $root_part"
# create root partition with label ArchLinux
mkfs.btrfs -L ArchLinux -f "$root_part"
# create subvlumes
echo "Creating btrfs subvolumes ..."
mount "$root_part" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@var_log
btrfs subvolume create /mnt/@pacman_pkgs
mkdir /mnt/@/{efi,home,.snapshots}
mkdir -p /mnt/@/var/log
mkdir -p /mnt/@/var/cache/pacman/pkg
umount "$root_part"

# mount all partitions
echo -e "\nMounting all partitions ..."
mount -o "$BTRFS_MOUNT_OPTS",subvol=@ "$root_part" /mnt
# https://wiki.archlinux.org/title/Security#Mount_options
# Mount file system with nodev,nosuid,noexec except /home partition.
home_mount_opts="$BTRFS_MOUNT_OPTS,nodev"

mount -o "$home_mount_opts,subvol=@home" "$root_part" /mnt/home
mount -o "$BTRFS_MOUNT_OPTS,nodev,nosuid,noexec,subvol=@snapshots" "$root_part" /mnt/.snapshots
mount -o "$BTRFS_MOUNT_OPTS,nodev,nosuid,noexec,subvol=@var_log" "$root_part" /mnt/var/log
mount -o "$BTRFS_MOUNT_OPTS,nodev,nosuid,noexec,subvol=@pacman_pkgs" "$root_part" /mnt/var/cache/pacman/pkg
mount "$efi_part" /mnt/efi

echo "
######################################################
# Install packages
# https://wiki.archlinux.org/title/Installation_guide#Install_essential_packages
######################################################
"
pacstrap -K /mnt $BASE_PKGS $KERNEL_PKGS $FS_PKGS $UCODE_PKG $OTHER_PKGS


echo "
######################################################
# Generate fstab
# https://wiki.archlinux.org/title/Installation_guide#Fstab
######################################################
"
echo -e "Generating fstab ..."
genfstab -U /mnt >> /mnt/etc/fstab
echo "Removing subvolid entry in fstab ..."
sed -i 's/subvolid=[0-9]*,//g' /mnt/etc/fstab


echo "
######################################################
# Set time zone
# https://wiki.archlinux.org/title/Installation_guide#Time_zone
######################################################
"
echo -e "Setting time zone ..."
arch-chroot /mnt ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
arch-chroot /mnt hwclock --systohc

echo "
######################################################
# Set locale
# https://wiki.archlinux.org/title/Installation_guide#Localization
######################################################
"
echo -e "Setting locale ..."
# uncomment en_US.UTF-8 UTF-8
arch-chroot /mnt sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
# uncomment other UTF-8 locales
if [[ $LANG != 'en_US.UTF-8' ]] ; then
    arch-chroot /mnt sed -i "s/^#$LANG UTF-8/$LANG UTF-8/" /etc/locale.gen
fi
arch-chroot /mnt locale-gen
echo "LANG=$LANG" > /mnt/etc/locale.conf
echo "KEYMAP=$KEYMAP" > /mnt/etc/vconsole.conf

echo "
######################################################
# Set network
# https://wiki.archlinux.org/title/Installation_guide#Network_configuration
######################################################
"
echo -e "Setting network ..."
echo -e "\n\nPlease tell me the hostname:"
read hostname
echo "$hostname" > /mnt/etc/hostname
ln -sf ../run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf
echo -e "\nWhich network manager do you want to use?\n\t1\tsystemd-networkd\n\t2\tNetworkManger"
read -p "Please enter a number: " networkmanager
if [[ $networkmanager -eq 1 ]] ; then
    echo -e "Copying iso network configuration ..."
    cp /etc/systemd/network/20-ethernet.network /mnt/etc/systemd/network/20-ethernet.network
    echo "Enabling systemd-resolved.service and systemd-networkd.service ..."
    arch-chroot /mnt systemctl enable systemd-resolved.service
    arch-chroot /mnt systemctl enable systemd-networkd.service
    read -p "Install and enable iwd (for WiFi) ? [y/N] " install_iwd
    install_iwd="${install_iwd:-n}"
    INSTALL_IWD="${install_iwd,,}"
    if [[ $install_iwd == y ]] ; then
        arch-chroot /mnt pacman --noconfirm -S iwd
        arch-chroot /mnt systemctl enable iwd.service
    fi
elif [[ "$networkmanager" -eq 2 ]] ; then
    echo "Installing NetworkManager and wpa_supplicant ..."
    arch-chroot /mnt pacman --noconfirm -S networkmanager wpa_supplicant
    echo "Enabling systemd-resolved.service and NetworkManager.service and wpa_supplicant.service ..."
    arch-chroot /mnt systemctl enable systemd-resolved.service
    arch-chroot /mnt systemctl enable NetworkManager.service
    arch-chroot /mnt systemctl enable wpa_supplicant.service
else
    echo "Invalid option."
    exit 1
fi


# reload partition table
partprobe &> /dev/null
# wait for partition table update
sleep 1
root_uuid=$(lsblk -dno UUID $root_block)
efi_uuid=$(lsblk -dno UUID $efi_part)


# mkinitcpio
# https://wiki.archlinux.org/title/Dm-crypt/System_configuration#mkinitcpio
echo "Editing mkinitcpio ..."
sed -i '/^HOOKS=/ s/ keyboard//' /mnt/etc/mkinitcpio.conf
sed -i '/^HOOKS=/ s/ udev//' /mnt/etc/mkinitcpio.conf
sed -i '/^HOOKS=/ s/ keymap//' /mnt/etc/mkinitcpio.conf
sed -i '/^HOOKS=/ s/ consolefont//' /mnt/etc/mkinitcpio.conf
sed -i '/^HOOKS=/ s/base/base systemd keyboard/' /mnt/etc/mkinitcpio.conf
sed -i '/^HOOKS=/ s/block/sd-vconsole block' /mnt/etc/mkinitcpio.conf
kernel_cmd="root=UUID=$root_uuid"



# btrfs as root
# https://wiki.archlinux.org/title/Btrfs#Mounting_subvolume_as_root
kernel_cmd="$kernel_cmd rootfstype=btrfs rootflags=subvol=/@ rw"
# modprobe.blacklist=pcspkr will disable PC speaker (beep) globally
# https://wiki.archlinux.org/title/PC_speaker#Globally
kernel_cmd="$kernel_cmd modprobe.blacklist=pcspkr $KERNEL_PARAMETERS"


echo "
######################################################
# zram
# https://wiki.archlinux.org/title/Zram
######################################################
"
read -p "Do you want to enable zram, and disable zswap? [Y/n] " zram
zram="${zram:-y}"
zram="${zram,,}"
if [[ $zram == y ]] ; then
    # disable zswap
    kernel_cmd="$kernel_cmd zswap.enabled=0"
    # install zram-generator
    arch-chroot /mnt pacman --noconfirm -S zram-generator
    # Create /etc/systemd/zram-generator.conf
    if [[ -z $ZRAM_SIZE ]] ; then
        ZRAM_SIZE='min(ram / 2, 4096)'
    fi
    echo "[zram0]"                       > /mnt/etc/systemd/zram-generator.conf
    echo "zram-size = $ZRAM_SIZE"       >> /mnt/etc/systemd/zram-generator.conf
    echo "compression-algorithm = zstd" >> /mnt/etc/systemd/zram-generator.conf
    echo "fs-type = swap"               >> /mnt/etc/systemd/zram-generator.conf

    echo "vm.swappiness = 180"              > /mnt/etc/sysctl.d/99-vm-zram-parameters.conf
    echo "vm.watermark_boost_factor = 0"   >> /mnt/etc/sysctl.d/99-vm-zram-parameters.conf
    echo "vm.watermark_scale_factor = 125" >> /mnt/etc/sysctl.d/99-vm-zram-parameters.conf
    echo "vm.page-cluster = 0"             >> /mnt/etc/sysctl.d/99-vm-zram-parameters.conf
fi


# Fallback kernel cmdline parameters (without SELinux, VFIO)
echo "$kernel_cmd" > /mnt/etc/kernel/cmdline_fallback

echo "
######################################################
# Setup unified kernel image
# https://wiki.archlinux.org/title/Unified_kernel_image
######################################################
"
arch-chroot /mnt mkdir -p /efi/EFI/Linux
for KERNEL in $KERNEL_PKGS
do
    # Edit default_uki= and fallback_uki=
    sed -i -E "s@^(#|)default_uki=.*@default_uki=\"/efi/EFI/Linux/ArchLinux-$KERNEL.efi\"@" /mnt/etc/mkinitcpio.d/$KERNEL.preset
    sed -i -E "s@^(#|)fallback_uki=.*@fallback_uki=\"/efi/EFI/Linux/ArchLinux-$KERNEL-fallback.efi\"@" /mnt/etc/mkinitcpio.d/$KERNEL.preset
    # Edit default_options= and fallback_options=
    sed -i -E "s@^(#|)default_options=.*@default_options=\"--splash /usr/share/systemd/bootctl/splash-arch.bmp\"@" /mnt/etc/mkinitcpio.d/$KERNEL.preset
    sed -i -E "s@^(#|)fallback_options=.*@fallback_options=\"-S autodetect --cmdline /etc/kernel/cmdline_fallback\"@" /mnt/etc/mkinitcpio.d/$KERNEL.preset
    # comment out default_image= and fallback_image=
    sed -i -E "s@^(#|)default_image=.*@#&@" /mnt/etc/mkinitcpio.d/$KERNEL.preset
    sed -i -E "s@^(#|)fallback_image=.*@#&@" /mnt/etc/mkinitcpio.d/$KERNEL.preset
done

# remove leftover initramfs-*.img from /boot or /efi
rm /mnt/efi/initramfs-*.img 2>/dev/null
rm /mnt/boot/initramfs-*.img 2>/dev/null

echo "$kernel_cmd" > /mnt/etc/kernel/cmdline
echo "Regenerating the initramfs ..."
arch-chroot /mnt mkinitcpio -P

echo "
######################################################
# Set up bootloader systemd-boot
# https://wiki.archlinux.org/title/systemd-boot
######################################################
"
arch-chroot /mnt bootctl install

echo "
######################################################
# OpenSSH server
# https://wiki.archlinux.org/title/OpenSSH#Server_usage
######################################################
"
read -p "Do you want to enable ssh? [y/N] " enable_ssh
enable_ssh="${enable_ssh:-n}"
enable_ssh="${enable_ssh,,}"
if [[ $enable_ssh == y ]] ; then
    if [[ $selinux == n ]] ; then
        arch-chroot /mnt pacman --noconfirm -S --needed openssh
    else
        arch-chroot /mnt pacman --noconfirm -S --needed openssh-selinux
    fi
    arch-chroot /mnt systemctl enable sshd.service
    echo " Enabled sshd.service"
    echo "ssh port? (22)"
    read ssh_port
    ssh_port="${ssh_port:-22}"
    if [[ $ssh_port != 22 ]] ; then
        sed -i "s/^#Port.*/Port ${ssh_port}/" /mnt/etc/ssh/sshd_config
    fi
fi


echo "
######################################################
# Firewalld
# https://wiki.archlinux.org/title/firewalld
######################################################
"
arch-chroot /mnt pacman --noconfirm -S --needed firewalld
arch-chroot /mnt systemctl enable firewalld.service
echo "Set default firewall zone to drop."
arch-chroot /mnt firewall-offline-cmd --set-default-zone=drop
if [[ $enable_ssh == y ]] ; then
    if [[ $ssh_port != 22 ]] ; then
        echo "modify default ssh service with new port."
        sed "/port=/s/port=\"22\"/port=\"${ssh_port}\"/" /mnt/usr/lib/firewalld/services/ssh.xml  > /mnt/etc/firewalld/services/ssh.xml
    fi
    echo -e "\nssh allow source ip address (example 192.168.1.0/24) empty to allow all"
    read ssh_source
    if [[ -n $ssh_source ]] ; then
        arch-chroot /mnt firewall-offline-cmd --zone=drop --add-rich-rule="rule family='ipv4' source address='${ssh_source}' service name='ssh' accept"
    else
        arch-chroot /mnt firewall-offline-cmd --zone=drop --add-service ssh
    fi
fi
echo -e "\n"
read -p "Allow ICMP echo-request and echo-reply (respond ping)? [Y/n] "
allow_ping="${allow_ping:-y}"
allow_ping="${allow_ping,,}"
if [[ $allow_ping == y ]] ; then
    arch-chroot /mnt firewall-offline-cmd --zone=drop --add-icmp-block-inversion
    echo -e "\nallow ping source ip address (example 192.168.1.0/24) empty to allow all"
    read ping_source
    if [[ -n $ping_source ]] ; then
        arch-chroot /mnt firewall-offline-cmd --zone=drop --add-rich-rule="rule family='ipv4' source address='${ping_source}' icmp-type name='echo-request' accept"
        arch-chroot /mnt firewall-offline-cmd --zone=drop --add-rich-rule="rule family='ipv4' source address='${ping_source}' icmp-type name='echo-reply' accept"
    else
        arch-chroot /mnt firewall-offline-cmd --zone=drop --add-icmp-block=echo-request
        arch-chroot /mnt firewall-offline-cmd --zone=drop --add-icmp-block=echo-reply
    fi
fi


echo "
######################################################
# User account
# https://wiki.archlinux.org/title/Users_and_groups
######################################################
"
# add wheel group to sudoer
sed -i '/^# %wheel ALL=(ALL:ALL) ALL/ s/# //' /mnt/etc/sudoers

read -p "Tell me your username: " username
arch-chroot /mnt useradd -m -G wheel "$username"
arch-chroot /mnt passwd "$username"

echo "Enter root password"
arch-chroot /mnt passwd

echo -e "\n\nNow you could reboot or chroot into the new system at /mnt to do further changes.\n\n"