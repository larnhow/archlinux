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
echo "Mounting File Systems..."
mount ${ROOTFS} $rootmnt
mkdir $rootmnt/efi -p
mount -t vfat ${ESP} $rootmnt/efi

lsblk
read -p "Press Key to continue"
