# Archlinux

## Install

### Partition

```
device=/dev/vda
```

```
blkdiscard $device -f && \
sgdisk --zap-all "${device}"
```

```
sgdisk -g "${device}" && \
sgdisk -I -n 1:0:+2048M -t 1:ef00 -c 1:'efi' "${device}" && \
sgdisk -I -n 2:0:0 -t 2:8309 -c 2:'luksroot' "${device}"
```

### Luks2
```
ESP='/dev/disk/by-partlabel/efi' && \
ROOTFS='/dev/disk/by-partlabel/luksroot'

cryptsetup luksFormat --type luks2 --sector-size 4096 ${ROOTFS} && \
cryptsetup open "$CRYPTROOT" luksroot

cryptsetup --allow-discards --perf-no_read_workqueue --perf-no_write_workqueue --persistent refresh luks-36cade11-7756-4c7e-8cef-9d76367befb5

```

### Filesystems

```
BTRFS="/dev/mapper/luksroot"

mkfs.vfat -F32 -n EFI ${ESP}
mkfs.btrfs -L fsroot "$BTRFS"
```


#### Creating BTRFS subvolumes.
```
mount "$BTRFS" /mnt && \
btrfs subvolume create /mnt/@ && \
btrfs subvolume create /mnt/@home && \
btrfs subvolume create /mnt/@snapshots && \
btrfs subvolume create /mnt/@var_log && \
umount /mnt

```

#### Mounting the newly created subvolumes.

```
mount -o ssd,noatime,compress-force=zstd:1,discard=async,subvol=@ "$BTRFS" /mnt/

mkdir -p /mnt/{home,.snapshots,var/log}

mount -o ssd,noatime,compress-force=zstd:1,discard=async,subvol=@home "$BTRFS" /mnt/home
mount -o ssd,noatime,compress-force=zstd:1,discard=async,subvol=@snapshots "$BTRFS" /mnt/.snaphots
mount -o ssd,noatime,compress-force=zstd:1,discard=async,subvol=@var_log "$BTRFS" /mnt/var/log

mkdir /mnt/efi
mount "$ESP" /mnt/efi
```

### Arch Base Config

```
genfstab -t PARTLABEL /mnt >> /mnt/etc/fstab

reflector --country DE --age 24 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
```

#### Base Install

```
pacstrap -K /mnt base base-devel linux linux-firmware amd-ucode intel-ucode vim nano micro helix cryptsetup btrfs-progs dosfstools util-linux git unzip sbctl systemd-ukif networkmanager sudo 
```

#### Base Config

```
sed -i -e "/^#"en_US.UTF-8"/s/^#//" /mnt/etc/locale.gen
sed -i -e "/^#"de_DE.UTF-8"/s/^#//" /mnt/etc/locale.gen

systemd-firstboot --root /mnt --prompt

arch-chroot /mnt locale-gen

arch-chroot /mnt useradd -G wheel -m gandor
arch-chroot /mnt passwd gandor
sed -i -e '/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/s/^# //' /mnt/etc/sudoers

ln -sf ../run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf
```

#### UKI

```
echo "quiet rw" >/mnt/etc/kernel/cmdline
mkdir -p /mnt/efi/EFI/Linux
```

nano /mnt/etc/mkinitcpio.conf

```
sed -i -e "base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck/s/base systemd autodetect modconf kms keyboard sd-vconsole sd-encrypt block filesystems fsck" /mnt/etc/mkinitcpio.conf
```

```
HOOKS=(base systemd autodetect modconf kms keyboard sd-vconsole sd-encrypt block filesystems fsck)
```

nano /mnt/etc/mkinitcpio.d/linux.preset
##### mkinitcpio preset file to generate UKIs

```
ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux"
ALL_microcode=(/boot/*-ucode.img)

PRESETS=('default' 'fallback')

#default_config="/etc/mkinitcpio.conf"
#default_image="/boot/initramfs-linux.img"
default_uki="/efi/EFI/Linux/arch-linux.efi"
default_options="--splash /usr/share/systemd/bootctl/splash-arch.bmp"

#fallback_config="/etc/mkinitcpio.conf"
#fallback_image="/boot/initramfs-linux-fallback.img"
fallback_uki="/efi/EFI/Linux/arch-linux-fallback.efi"
fallback_options="-S autodetect"
```

#### Create UKI and install Bootloader

```
arch-chroot /mnt mkinitcpio -P

systemctl --root /mnt enable systemd-resolved systemd-timesyncd NetworkManager
systemctl --root /mnt mask systemd-networkd
arch-chroot /mnt bootctl install --esp-path=/efi
```

### Reboot
```
umount -R /mnt && reboot
```



## Drucker

```
sudo pacman -Syu cups cups-pdf system-config-printer avahi nss-mdns && \
sudo systemctl enable --now cups && \
sudo systemctl enable --now avahi-daemon && \
sudo nano /etc/nsswitch.conf
```

```
hosts: mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns 
```

```
sudo systemctl restart avahi-daemon
```

```
lpadmin -p xerox -v ipp://xerox.home.arpa/ipp/print -m everywhere
```

## CPU
### intel

```
sudo pacman -Syu thermald power-profiles-daemon && \
sudo systemctl enable --now thermald.service && \
sudo systemctl enable --now power-profiles-daemon
```

### amd
```
sudo pacman -Syu power-profiles-daemon && \
sudo systemctl enable --now power-profiles-daemon
```
    
## cli
    sudo pacman -Syu helix git fish eza zoxide fd ripgrep yazi starship btop chezmoi nvtop openssh git cifs-utils --needed
    
## gui    
    sudo pacman -Syu firefox firefox-i18n-de thunderbird thunderbird-i18n-de mpv ttf-jetbrains-mono-nerd --needed
    
## Plasma KDE
     sudo pacman -Syu plasma-meta kde-applications-meta

## dolphin
    sudo pacman -Syu kdegraphics-thumbnailers kimageformats qt6-imageformats ffmpegthumbs icoutils --needed

## libreoffice
    sudo pacman -Syu libreoffice-fresh ttf-caladea ttf-carlito ttf-dejavu ttf-liberation ttf-linux-libertine-g noto-fonts adobe-source-code-pro-fonts adobe-source-sans-fonts adobe-source-serif-fonts hunspell hunspell-de hunspell-en_us hyphen hyphen-en hyphen-de libmythes mythes-en mythes-de languagetool jdk-openjdk --needed
    
## bluetooth


    sudo pacman -Syu bluez bluez-utils blueman --needed
    sudo systemctl enable --now bluetooth.service

## network shares

```
#!/bin/bash
sudo mkdir -p /mnt/gandor
sudo mkdir -p /mnt/medis

sudo mkdir -p /etc/samba/credentials

echo -n "username for share gandor: "
read username
echo -n Password: 
read -s password

echo "username=$username" | sudo tee /etc/samba/credentials/gandor >/dev/null
echo "password=$password" | sudo tee -a /etc/samba/credentials/gandor >/dev/null

echo
echo -n "username for share media: "
read username
echo -n Password: 
read -s password

echo "username=$username" | sudo tee /etc/samba/credentials/media >/dev/null
echo "password=$password" | sudo tee -a /etc/samba/credentials/media >/dev/null

sudo chown root:root /etc/samba/credentials
sudo chmod 700 /etc/samba/credentials
sudo chmod 600 /etc/samba/credentials/gandor
sudo chmod 600 /etc/samba/credentials/media

echo

if grep '//nuc8.home.arpa/gandor' /etc/fstab > /dev/null
then
  echo "share gandor already in /etc/fstab"
else
  echo '//nuc8.home.arpa/gandor    /mnt/gandor    cifs    defaults,noauto,nofail,credentials=/etc/samba/credentials/gandor,x-systemd.automount,x-systemd.requires=network-online.target,gid=1000,uid=1000    0    0' | sudo tee -a /etc/fstab
fi

if grep '//nuc8.home.arpa/media' /etc/fstab > /dev/null
then
  echo "share media already in /etc/fstab"
else
  echo '//nuc8.home.arpa/media    /mnt/media    cifs    defaults,noauto,nofail,credentials=/etc/samba/credentials/media,x-systemd.automount,x-systemd.requires=network-online.target,gid=1000,uid=1000    0    0' | sudo tee -a /etc/fstab
fi
sudo systemctl daemon-reload 




```


## games

```
sudo pacman -Syu steam lutris gamemode lib32-gamemode gamescope
sudo usermod -aG gamemode gandor
    
```

## flatpak
```
sudo pacman -Syu flatpak --needed
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

flatpak install \
          com.github.tchx84.Flatseal \
          com.heroicgameslauncher.hgl \
          com.mikrotik.WinBox \
          io.github.dvlv.boxbuddyrs \
          io.github.flattool.Warehouse \
          io.missioncenter.MissionCenter \
          net.davidotek.pupgui2 \
          org.keepassxc.KeePassXC
```

## Virtualisation

### podman
    sudo pacman -Syu podman --needed



## encryption optimal
    sudo cryptsetup luksDump /dev/sdb2
    sudo cryptsetup --allow-discards --perf-no_read_workqueue --perf-no_write_workqueue --persistent refresh luks-36cade11-7756-4c7e-8cef-9d76367befb5


https://web.archive.org/web/20220809162619/https://lunaryorn.com/arch-linux-with-luks-and-almost-no-configuration

https://wiki.archlinux.org/title/User:Bai-Chiang/Arch_Linux_installation_with_unified_kernel_image_(UKI),_full_disk_encryption,_secure_boot,_btrfs_snapshots,_and_common_setups

https://github.com/yagebu/


https://walian.co.uk/arch-install-with-secure-boot-btrfs-tpm2-luks-encryption-unified-kernel-images.html





## printer
sudo pacman -Syu cups cups-pdf system-config-printer avahi nss-mdns
sudo systemctl enable --now cups
sudo systemctl enable --now avahi-daemon
sudo nano /etc/nsswitch.conf
    hosts: mymachines mdns_minimal [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns
sudo systemctl restart avahi-daemon