
AddPackage base # Minimal package set to define a basic Arch Linux installation
AddPackage base-devel # Basic tools to build Arch Linux packages
AddPackage btrfs-progs # Btrfs filesystem utilities
AddPackage dosfstools # DOS filesystem utilities
AddPackage e2fsprogs # Ext2/3/4 filesystem utilities
AddPackage firefox # Fast, Private & Safe Web Browser
AddPackage firefox-i18n-de # German language pack for Firefox
AddPackage firewalld # Firewall daemon with D-Bus interface
AddPackage git # the fast distributed version control system
AddPackage helix # A post-modern modal text editor
AddPackage hyprland # a highly customizable dynamic tiling Wayland compositor
AddPackage intel-ucode # Microcode update files for Intel CPUs
AddPackage iptables-nft # Linux kernel packet control tool (using nft interface)
AddPackage kitty # A modern, hackable, featureful, OpenGL-based terminal emulator
AddPackage linux # The Linux kernel and modules
AddPackage linux-firmware # Firmware files for Linux
AddPackage man-db # A utility for reading man pages
AddPackage micro # Modern and intuitive terminal-based text editor
AddPackage networkmanager # Network connection manager and user applications
AddPackage openssh # SSH protocol implementation for remote login, command execution and file transfer
AddPackage sudo # Give certain users the ability to run some commands as root
AddPackage wofi # launcher for wlroots-based wayland compositors
AddPackage wpa_supplicant # A utility providing key negotiation for WPA wireless networks
AddPackage zram-generator # Systemd unit generator for zram devices

AddPackage edk2-shell #	EDK2 UEFI Shell
AddPackage ripgrep
# Mi 27. Nov 11:27:59 CET 2024 - Unknown foreign packages


AddPackage --foreign aconfmgr-git # A configuration manager for Arch Linux

# /etc/locale.gen - Enable locale generation
f="$(GetPackageOriginalFile glibc /etc/locale.gen)"
sed -i 's/^#\(de_DE.UTF-8\)/\1/g' "$f"
#sed -i 's/^#\(en_GB.UTF-8\)/\1/g' "$f"
sed -i 's/^#\(en_US.UTF-8\)/\1/g' "$f"

f="$(GetPackageOriginalFile mkinitcpio /etc/mkinitcpio.conf)"
sed -i '/^HOOKS=/ s/ keyboard//' /etc/mkinitcpio.conf
sed -i '/^HOOKS=/ s/ udev//' /etc/mkinitcpio.conf
sed -i '/^HOOKS=/ s/ keymap//' /etc/mkinitcpio.conf
sed -i '/^HOOKS=/ s/ consolefont//' /etc/mkinitcpio.conf
sed -i '/^HOOKS=/ s/base/base systemd keyboard/' /etc/mkinitcpio.conf
sed -i '/^HOOKS=/ s/block/sd-vconsole block' /etc/mkinitcpio.conf


f="$(GetPackageOriginalFile packmano /etc/pacman.conf)"
sed -i '/ParallelDownloads/s/^#//g' /etc/pacman.conf
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf # Enable Multilib



CreateLink /etc/localtime /usr/share/zoneinfo/Europe/Berlin
CopyFile /etc/mkinitcpio.d/linux.preset
CreateLink /etc/os-release ../usr/lib/os-release
CreateLink /etc/resolv.conf ../run/systemd/resolve/stub-resolv.conf
CreateLink /etc/systemd/system/dbus-fi.w1.wpa_supplicant1.service /usr/lib/systemd/system/wpa_supplicant.service
CreateLink /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service /usr/lib/systemd/system/firewalld.service
CreateLink /etc/systemd/system/dbus-org.freedesktop.nm-dispatcher.service /usr/lib/systemd/system/NetworkManager-dispatcher.service
CreateLink /etc/systemd/system/dbus-org.freedesktop.resolve1.service /usr/lib/systemd/system/systemd-resolved.service
CreateLink /etc/systemd/system/getty.target.wants/getty@tty1.service /usr/lib/systemd/system/getty@.service
CreateLink /etc/systemd/system/multi-user.target.wants/NetworkManager.service /usr/lib/systemd/system/NetworkManager.service
CreateLink /etc/systemd/system/multi-user.target.wants/firewalld.service /usr/lib/systemd/system/firewalld.service
CreateLink /etc/systemd/system/multi-user.target.wants/remote-fs.target /usr/lib/systemd/system/remote-fs.target
CreateLink /etc/systemd/system/multi-user.target.wants/wpa_supplicant.service /usr/lib/systemd/system/wpa_supplicant.service
CreateLink /etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service /usr/lib/systemd/system/NetworkManager-wait-online.service
CreateLink /etc/systemd/system/sockets.target.wants/systemd-userdbd.socket /usr/lib/systemd/system/systemd-userdbd.socket
CreateLink /etc/systemd/system/sysinit.target.wants/systemd-resolved.service /usr/lib/systemd/system/systemd-resolved.service
CreateLink /etc/systemd/user/pipewire-session-manager.service /usr/lib/systemd/user/wireplumber.service
CreateLink /etc/systemd/user/pipewire.service.wants/wireplumber.service /usr/lib/systemd/user/wireplumber.service
CreateLink /etc/systemd/user/sockets.target.wants/p11-kit-server.socket /usr/lib/systemd/user/p11-kit-server.socket
CreateLink /etc/systemd/user/sockets.target.wants/pipewire.socket /usr/lib/systemd/user/pipewire.socket
CopyFile /etc/systemd/zram-generator.conf
CopyFile /etc/vconsole.conf
