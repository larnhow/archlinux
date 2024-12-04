#!/bin/bash
# uncomment to view debugging information 
#set -xeuo pipefail

#check if we're root
if [[ "$UID" -ne 0 ]]; then
    echo "This script needs to be run as root!" >&2
    exit 3
fi

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

### Config options
target="/dev/vda"
rootmnt="/mnt"
locale="de_DE.UTF-8"
keymap="de-latin1"
timezone="Europe/Berlin"
hostname="install"
username="gandor"
#SHA512 hash of password. To generate, run 'mkpasswd -m sha-512', don't forget to prefix any $ symbols with \ . The entry below is the hash of 'password'
user_password="\$6\$/VBa6GuBiFiBmi6Q\$yNALrCViVtDDNjyGBsDG7IbnNR0Y/Tda5Uz8ToyxXXpw86XuCVAlhXlIvzy1M8O.DWFB6TRCia0hMuAJiXOZy/"

#To fully automate the setup, change badidea=no to yes, and enter a cleartext password for the disk encryption 

badidea="no"
crypt_password="changeme"


### Packages to pacstrap ##
pacstrappacs=(
        base
        linux
        linux-firmware
        $microcode
        helix
        nano
        cryptsetup
        util-linux
        e2fsprogs
        dosfstools
        sudo
        networkmanager
	git
 	openssh
        )    
### Desktop packages #####
guipacs=(
	plasma 
	sddm 
	kitty
	firefox 
	nm-connection-editor
	neofetch
	mousepad
 	sbctl
  	firefox
   	firefox-i18n-de
	)

echo "
######################################################
# Modify pacman.conf
######################################################
"
sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf # Enable Multilib

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
        blkdiscard $device -f
	sgdisk --zap-all "${device}"
	echo "Creating new partition scheme on ${device}."
	sgdisk -g "${device}"
	sgdisk -I -n 1:0:+512M -t 1:ef00 -c 1:'ESP' "${device}"
	sgdisk -I -n 2:0:0 -t 2:8304 -c 2:'rootfs' "${device}"
    fi
done

# Reload partition table
sleep 2
partprobe -s "$device"
sleep 2

ESP='/dev/disk/by-partlabel/ESP'
ROOTFS='/dev/disk/by-partlabel/rootfs'

ls $ESP
ls $ROOTFS

lsblk
read -p "Press Key to continue"


echo "Making File Systems..."
# Create file systems
mkfs.vfat -F32 -n ESP ${ESP}
mkfs.ext4 -m 0 -L Archlinux ${ROOTFS}

# mount the root, and create + mount the EFI directory
rootmnt=/mnt
echo "Mounting File Systems..."
mount ${ROOTFS} $rootmnt
mkdir $rootmnt/efi -p
mount -t vfat ${ESP} $rootmnt/efi

lsblk
read -p "Press Key to continue"

#Update pacman mirrors and then pacstrap base install
echo "Pacstrapping..."
reflector --country DE --age 24 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
pacstrap -K $rootmnt "${pacstrappacs[@]}" 

echo "Setting up environment..."
#set up locale/env
#add our locale to locale.gen
sed -i -e "/^#"$locale"/s/^#//" "$rootmnt"/etc/locale.gen
sed -i -e "/^#us_US/s/^#//" "$rootmnt"/etc/locale.gen
#remove any existing config files that may have been pacstrapped, systemd-firstboot will then regenerate them
rm "$rootmnt"/etc/{machine-id,localtime,hostname,shadow,locale.conf} ||
systemd-firstboot --root "$rootmnt" \
	--keymap="$keymap" --locale="$locale" \
	--locale-messages="$locale" --timezone="$timezone" \
	--hostname="$hostname" --setup-machine-id \
	--welcome=false
arch-chroot "$rootmnt" locale-gen
echo "Configuring for first boot..."
#add the local user
arch-chroot "$rootmnt" useradd -G wheel -m "$username" 
#uncomment the wheel group in the sudoers file
sed -i -e '/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^# //' "$rootmnt"/etc/sudoers
#create a basic kernel cmdline, we're using DPS so we don't need to have anything here really, but if the file doesn't exist, mkinitcpio will complain
echo "quiet rw" > "$rootmnt"/etc/kernel/cmdline
#change the HOOKS in mkinitcpio.conf to use systemd hooks
sed -i \
    -e 's/base udev/base systemd/g' \
    -e 's/keymap consolefont/sd-vconsole sd-encrypt/g' \
    "$rootmnt"/etc/mkinitcpio.conf
#change the preset file to generate a Unified Kernel Image instead of an initram disk + kernel
sed -i \
    -e '/^#ALL_config/s/^#//' \
    -e '/^#default_uki/s/^#//' \
    -e '/^#default_options/s/^#//' \
    -e 's/default_image=/#default_image=/g' \
    -e "s/PRESETS=('default' 'fallback')/PRESETS=('default')/g" \
    "$rootmnt"/etc/mkinitcpio.d/linux.preset

#read the UKI setting and create the folder structure otherwise mkinitcpio will crash
declare $(grep default_uki "$rootmnt"/etc/mkinitcpio.d/linux.preset)
arch-chroot "$rootmnt" mkdir -p "$(dirname "${default_uki//\"}")"

#install the gui packages
echo "Installing GUI..."
arch-chroot "$rootmnt" pacman -Sy "${guipacs[@]}" --noconfirm --quiet


#enable the services we will need on start up
echo "Enabling services..."
systemctl --root "$rootmnt" enable systemd-resolved systemd-timesyncd NetworkManager sddm
#mask systemd-networkd as we will use NetworkManager instead
systemctl --root "$rootmnt" mask systemd-networkd
#regenerate the ramdisk, this will create our UKI
echo "Generating UKI and installing Boot Loader..."
arch-chroot "$rootmnt" mkinitcpio -p linux

#install the systemd-boot bootloader
arch-chroot "$rootmnt" bootctl install --esp-path=/efi
#lock the root account
#arch-chroot "$rootmnt" usermod -L root
#and we're done


echo "-----------------------------------"
echo "- Install complete. Rebooting.... -"
echo "-----------------------------------"
sleep 10
sync
reboot
