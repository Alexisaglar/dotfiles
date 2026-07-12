#!/usr/bin/env bash

### -------- GET WIFI ON LAPTOP FIRST --------
# iwctl
# device list
# station wlan0 scan
# station wlan0 get-networks
# station wlan0 connect "Your-WiFi-Name"
# exit
# 
# ping -c 3 google.com
# 
# curl -LO https://github.com/Alexisaglar/dotfiles/archlinux/arch_script.sh
# chmod +x arch_script
# ./arch_script

set -e

echo "=== Arch Linux Installer ==="
read -p "EFI partition (e.g. /dev/nvme0n1p1): " EFI
read -p "ROOT partition (e.g. /dev/nvme0n1p2): " ROOT
read -p "Hostname: " HOSTNAME 
read -p "Username: " USER
read -p "Full Name: " NAME
read -sp "Password: " PASSWORD
echo
read -p "Wi-Fi Network Name (SSID): " WIFI_SSID
read -sp "Wi-Fi Password: " WIFI_PASS
echo
read -p "Git URL for your Dotfiles (e.g. https://github.com/user/repo.git): " DOTFILES_REPO
echo
echo "Which processor does this laptop have?"
echo "1) Intel"
echo "2) AMD"
read -p "Select 1 or 2: " CPU_CHOICE

if [ "$CPU_CHOICE" == "1" ]; then
    UCODE="intel-ucode"
    UCODE_IMG="/intel-ucode.img"
    GPU_MODULE="i915"
else
    UCODE="amd-ucode"
    UCODE_IMG="/amd-ucode.img"
    GPU_MODULE="amdgpu"
fi
echo

### -------- FILESYSTEM --------
mkfs.fat -F32 "$EFI"
mkfs.ext4 -F "$ROOT"

mount -o noatime "$ROOT" /mnt
mkdir -p /mnt/boot
mount "$EFI" /mnt/boot

### -------- BASE ARCH & HYPRLAND ECOSYSTEM --------
pacman -Syy --noconfirm archlinux-keyring

# Installing base system, correct microcode, Mesa (graphics), and Wayland tools
pacstrap /mnt \
base base-devel linux linux-headers linux-firmware $UCODE mesa \
networkmanager vim git curl dkms \
zram-generator power-profiles-daemon bluez bluez-utils \
pipewire wireplumber pipewire-alsa pipewire-pulse pulseaudio-utils \
hyprland waybar rofi-wayland dunst hyprpaper swaybg \
swaylock swayidle brightnessctl playerctl grim slurp wl-clipboard \
network-manager-applet ghostty \
--noconfirm --needed

genfstab -U /mnt >> /mnt/etc/fstab
ROOT_UUID=$(blkid -s UUID -o value "$ROOT")

### -------- CHROOT SCRIPT --------
cat <<EOF > /mnt/next.sh
#!/usr/bin/env bash
set -e

### --- USER ---
useradd -m "$USER"
usermod -c "$NAME" "$USER"
usermod -aG wheel,video,audio,storage,power "$USER"
echo "$USER:$PASSWORD" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

### --- WIFI CONFIGURATION ---
cat <<'WIFI' > /etc/NetworkManager/system-connections/\${WIFI_SSID}.nmconnection
[connection]
id=\${WIFI_SSID}
type=wifi

[wifi]
ssid=\${WIFI_SSID}
mode=infrastructure

[wifi-security]
key-mgmt=wpa-psk
psk=\${WIFI_PASS}

[ipv4]
method=auto

[ipv6]
method=auto
WIFI
chmod 600 /etc/NetworkManager/system-connections/\${WIFI_SSID}.nmconnection

### --- LOCALE / TIME ---
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
ln -sf /usr/share/zoneinfo/Asia/Kathmandu /etc/localtime
hwclock --systohc

### --- HOSTNAME ---
echo "$HOSTNAME" > /etc/hostname
cat <<HOSTS > /etc/hosts
127.0.0.1 localhost
::1       localhost
127.0.1.1 ${HOSTNAME}.localdomain ${HOSTNAME}
HOSTS

### --- ZRAM ---
cat <<ZRAM > /etc/systemd/zram-generator.conf
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
swap-priority = 100
fs-type = swap
ZRAM

### --- AUR (yay) ---
cd /tmp
sudo -u "$USER" git clone https://aur.archlinux.org/yay.git
cd yay
sudo -u "$USER" makepkg -si --noconfirm
cd /
rm -rf /tmp/yay

### --- DOTFILES SETUP (SYMLINKS) ---
sudo -u "$USER" git clone "$DOTFILES_REPO" "/home/$USER/dotfiles"

sudo -u "$USER" mkdir -p "/home/$USER/.config/hypr"
sudo -u "$USER" mkdir -p "/home/$USER/.config/waybar"

# Linking files instead of copying them
sudo -u "$USER" ln -sf "/home/$USER/dotfiles/hyprland.conf" "/home/$USER/.config/hypr/hyprland.conf"
sudo -u "$USER" ln -sf "/home/$USER/dotfiles/hyprpaper.conf" "/home/$USER/.config/hypr/hyprpaper.conf"
sudo -u "$USER" ln -sf "/home/$USER/dotfiles/config" "/home/$USER/.config/waybar/config"
sudo -u "$USER" ln -sf "/home/$USER/dotfiles/style.css" "/home/$USER/.config/waybar/style.css"

### --- MKINITCPIO ---
sed -i "s/^MODULES=.*/MODULES=($GPU_MODULE)/" /etc/mkinitcpio.conf
sed -i 's/^HOOKS=.*/HOOKS=(systemd autodetect modconf kms keyboard sd-vconsole block filesystems fsck)/' /etc/mkinitcpio.conf
mkinitcpio -P

### --- BOOTLOADER (Systemd-boot) ---
bootctl install --path=/boot

cat <<LOADER > /boot/loader/loader.conf
default arch.conf
timeout 3
editor no
LOADER

cat <<ENTRY > /boot/loader/entries/arch.conf
title   ArchLinux
linux   /vmlinuz-linux
initrd  $UCODE_IMG
initrd  /initramfs-linux.img
options root=UUID=$ROOT_UUID rw quiet loglevel=3 rd.udev.log_level=3
ENTRY

### --- SERVICES ---
systemctl enable NetworkManager bluetooth power-profiles-daemon fstrim.timer
systemctl --global enable pipewire pipewire-pulse wireplumber

echo "INSTALLATION COMPLETE"
EOF

# Pass the exported variables into the chroot environment so they resolve properly
export WIFI_SSID
export WIFI_PASS
export GPU_MODULE
export UCODE_IMG

chmod +x /mnt/next.sh
arch-chroot /mnt /next.sh
rm /mnt/next.sh

