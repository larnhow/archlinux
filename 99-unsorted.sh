

AddPackage base # Minimal package set to define a basic Arch Linux installation
AddPackage base-devel # Basic tools to build Arch Linux packages
AddPackage efibootmgr # Linux user-space application to modify the EFI Boot Manager

AddPackage fish # Smart and user friendly shell intended mostly for interactive use
AddPackage git # the fast distributed version control system
AddPackage helix # A post-modern modal text editor
AddPackage htop # Interactive process viewer
AddPackage intel-ucode # Microcode update files for Intel CPUs
AddPackage iwd # Internet Wireless Daemon
AddPackage linux # The Linux kernel and modules
AddPackage linux-firmware # Firmware files for Linux
AddPackage nano # Pico editor clone with enhancements
AddPackage network-manager-applet # Applet for managing network connections
AddPackage networkmanager # Network connection manager and user applications

AddPackage smartmontools # Control and monitor S.M.A.R.T. enabled ATA and SCSI Hard Drives
AddPackage vim # Vi Improved, a highly configurable, improved version of the vi text editor
AddPackage vulkan-radeon # Open-source Vulkan driver for AMD GPUs
AddPackage wget # Network utility to retrieve files from the Web
AddPackage wireless_tools # Tools allowing to manipulate the Wireless Extensions

#AddPackage xf86-video-amdgpu # X.org amdgpu video driver
#AddPackage xf86-video-ati # X.org ati video driver
AddPackage xfsprogs # XFS filesystem utilities
AddPackage xorg-server # Xorg X server
#AddPackage xorg-xinit # X.Org initialisation program
AddPackage yazi # Blazing fast terminal file manager written in Rust, based on async I/O
AddPackage zram-generator # Systemd unit generator for zram devices


# GUI

## Hyprland
AddPackage dolphin # KDE File Manager
AddPackage dunst # Customizable and lightweight notification-daemon
AddPackage grim # Screenshot utility for Wayland
AddPackage hyprland # a highly customizable dynamic tiling Wayland compositor
AddPackage polkit-kde-agent # Daemon providing a polkit authentication UI for KDE
AddPackage qt5-wayland # Provides APIs for Wayland
AddPackage qt6-wayland # Provides APIs for Wayland
AddPackage sddm # QML based X11 and Wayland display manager
AddPackage slurp # Select a region in a Wayland compositor
AddPackage wofi # launcher for wlroots-based wayland compositors
AddPackage xdg-desktop-portal-hyprland # xdg-desktop-portal backend for hyprland
AddPackage xdg-utils # Command line tools that assist applications with a variety of desktop integration tasks## GUI Progs

## Gui APPs
AddPackage firefox # Fast, Private & Safe Web Browser
AddPackage firefox-i18n-de # German language pack for Firefox
AddPackage kitty # A modern, hackable, featureful, OpenGL-based terminal emulator

# Sound
AddPackage gst-plugin-pipewire # Multimedia graph framework - pipewire plugin
AddPackage libpulse # A featureful, general-purpose sound server (client library)
AddPackage pipewire # Low-latency audio/video router and processor
AddPackage pipewire-alsa # Low-latency audio/video router and processor - ALSA configuration
AddPackage pipewire-jack # Low-latency audio/video router and processor - JACK replacement
AddPackage pipewire-pulse # Low-latency audio/video router and processor - PulseAudio replacement# Di 3. Dez 09:40:48 CET 2024 - Unknown foreign packages
AddPackage wireplumber # Session / policy manager implementation for PipeWire

AddPackage --foreign aconfmgr-git # A configuration manager for Arch Linux


# Di 3. Dez 09:40:48 CET 2024 - New / changed files


CopyFile /etc/X11/xorg.conf.d/00-keyboard.conf
CreateLink /etc/fonts/conf.d/10-hinting-slight.conf /usr/share/fontconfig/conf.default/10-hinting-slight.conf
CreateLink /etc/fonts/conf.d/10-scale-bitmap-fonts.conf /usr/share/fontconfig/conf.default/10-scale-bitmap-fonts.conf
CreateLink /etc/fonts/conf.d/10-sub-pixel-rgb.conf /usr/share/fontconfig/conf.default/10-sub-pixel-rgb.conf
CreateLink /etc/fonts/conf.d/10-yes-antialias.conf /usr/share/fontconfig/conf.default/10-yes-antialias.conf
CreateLink /etc/fonts/conf.d/11-lcdfilter-default.conf /usr/share/fontconfig/conf.default/11-lcdfilter-default.conf
CreateLink /etc/fonts/conf.d/20-unhint-small-vera.conf /usr/share/fontconfig/conf.default/20-unhint-small-vera.conf
CreateLink /etc/fonts/conf.d/30-metric-aliases.conf /usr/share/fontconfig/conf.default/30-metric-aliases.conf
CreateLink /etc/fonts/conf.d/40-nonlatin.conf /usr/share/fontconfig/conf.default/40-nonlatin.conf
CreateLink /etc/fonts/conf.d/45-generic.conf /usr/share/fontconfig/conf.default/45-generic.conf
CreateLink /etc/fonts/conf.d/45-latin.conf /usr/share/fontconfig/conf.default/45-latin.conf
CreateLink /etc/fonts/conf.d/48-spacing.conf /usr/share/fontconfig/conf.default/48-spacing.conf
CreateLink /etc/fonts/conf.d/49-sansserif.conf /usr/share/fontconfig/conf.default/49-sansserif.conf
CreateLink /etc/fonts/conf.d/50-user.conf /usr/share/fontconfig/conf.default/50-user.conf
CreateLink /etc/fonts/conf.d/51-local.conf /usr/share/fontconfig/conf.default/51-local.conf
CreateLink /etc/fonts/conf.d/60-generic.conf /usr/share/fontconfig/conf.default/60-generic.conf
CreateLink /etc/fonts/conf.d/60-latin.conf /usr/share/fontconfig/conf.default/60-latin.conf
CreateLink /etc/fonts/conf.d/65-fonts-persian.conf /usr/share/fontconfig/conf.default/65-fonts-persian.conf
CreateLink /etc/fonts/conf.d/65-nonlatin.conf /usr/share/fontconfig/conf.default/65-nonlatin.conf
CreateLink /etc/fonts/conf.d/69-unifont.conf /usr/share/fontconfig/conf.default/69-unifont.conf
CreateLink /etc/fonts/conf.d/80-delicious.conf /usr/share/fontconfig/conf.default/80-delicious.conf
CreateLink /etc/fonts/conf.d/90-synthetic.conf /usr/share/fontconfig/conf.default/90-synthetic.conf
CopyFile /etc/kernel/cmdline
CopyFile /etc/locale.conf
CopyFile /etc/locale.gen
CreateLink /etc/localtime /usr/share/zoneinfo/Europe/Berlin
CopyFile /etc/mkinitcpio.conf
CopyFile /etc/mkinitcpio.d/linux.preset
CreateLink /etc/os-release ../usr/lib/os-release
CopyFile /etc/pacman.conf
CopyFile /etc/resolv.conf
CopyFile /etc/shells
CopyFile /etc/subgid
CreateFile /etc/subgid- > /dev/null
CopyFile /etc/subuid
CreateFile /etc/subuid- > /dev/null
CopyFile /etc/sudoers.d/00_gandor 440
CreateLink /etc/systemd/system/dbus-org.freedesktop.nm-dispatcher.service /usr/lib/systemd/system/NetworkManager-dispatcher.service
CreateLink /etc/systemd/system/dbus-org.freedesktop.timesync1.service /usr/lib/systemd/system/systemd-timesyncd.service
CreateLink /etc/systemd/system/getty.target.wants/getty@tty1.service /usr/lib/systemd/system/getty@.service
CreateLink /etc/systemd/system/multi-user.target.wants/NetworkManager.service /usr/lib/systemd/system/NetworkManager.service
CreateLink /etc/systemd/system/multi-user.target.wants/remote-fs.target /usr/lib/systemd/system/remote-fs.target
CreateLink /etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service /usr/lib/systemd/system/NetworkManager-wait-online.service
CreateLink /etc/systemd/system/sockets.target.wants/systemd-userdbd.socket /usr/lib/systemd/system/systemd-userdbd.socket
CreateLink /etc/systemd/system/sysinit.target.wants/systemd-timesyncd.service /usr/lib/systemd/system/systemd-timesyncd.service
CreateLink /etc/systemd/system/timers.target.wants/fstrim.timer /usr/lib/systemd/system/fstrim.timer
CreateLink /etc/systemd/user/pipewire-session-manager.service /usr/lib/systemd/user/wireplumber.service
CreateLink /etc/systemd/user/pipewire.service.wants/wireplumber.service /usr/lib/systemd/user/wireplumber.service
CreateLink /etc/systemd/user/sockets.target.wants/p11-kit-server.socket /usr/lib/systemd/user/p11-kit-server.socket
CreateLink /etc/systemd/user/sockets.target.wants/pipewire-pulse.socket /usr/lib/systemd/user/pipewire-pulse.socket
CreateLink /etc/systemd/user/sockets.target.wants/pipewire.socket /usr/lib/systemd/user/pipewire.socket
CopyFile /etc/systemd/zram-generator.conf
CopyFile /etc/vconsole.conf


# Di 3. Dez 09:40:49 CET 2024 - New file properties


SetFileProperty /usr/bin/groupmems group groups
SetFileProperty /usr/bin/groupmems mode 2750


# Di 3. Dez 09:46:38 CET 2024 - Unknown packages


AddPackage tuned # Daemon that performs monitoring and adaptive configuration of devices in the system
AddPackage tuned-ppd # Daemon that allows applications to easily transition to TuneD from power-profiles-daemon (PPD)


# Di 3. Dez 09:46:39 CET 2024 - New / changed files


CreateFile /etc/modprobe.d/tuned.conf > /dev/null
CreateLink /etc/systemd/system/graphical.target.wants/tuned-ppd.service /usr/lib/systemd/system/tuned-ppd.service
CreateLink /etc/systemd/system/multi-user.target.wants/tuned.service /usr/lib/systemd/system/tuned.service
CopyFile /etc/tuned/active_profile
CreateFile /etc/tuned/post_loaded_profile > /dev/null
CopyFile /etc/tuned/profile_mode
