#!/usr/bin/env bash
set -e

echo "=== Arch Linux + Hyprland Installer ==="
read -p "EFI partition (e.g. /dev/nvme0n1p1): " EFI
read -p "ROOT partition (e.g. /dev/nvme0n1p2): " ROOT
read -p "Username: " USER
read -p "Full Name: " NAME
read -sp "Password: " PASSWORD
echo
read -p "Wi-Fi Network Name (SSID): " WIFI_SSID
read -sp "Wi-Fi Password: " WIFI_PASS
echo
read -p "Git URL for your Dotfiles (e.g. https://github.com/user/repo.git): " DOTFILES_REPO
echo

### -------- FILESYSTEM --------
mkfs.fat -F32 "$EFI"
mkfs.ext4 -F "$ROOT"

mount -o noatime "$ROOT" /mnt
mkdir -p /mnt/boot
mount "$EFI" /mnt/boot

### -------- BASE ARCH & HYPRLAND ECOSYSTEM --------
pacman -Syy --noconfirm archlinux-keyring

# Combined base system and your specific graphical environment packages
pacstrap /mnt \
base base-devel linux linux-headers linux-firmware \
networkmanager vim git curl intel-ucode dkms \
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
# Give wheel group sudo access
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

### --- WIFI CONFIGURATION ---
# Creates a NetworkManager profile so Wi-Fi connects on first boot
cat <<'WIFI' > /etc/NetworkManager/system-connections/${WIFI_SSID}.nmconnection
[connection]
id=${WIFI_SSID}
type=wifi

[wifi]
ssid=${WIFI_SSID}
mode=infrastructure

[wifi-security]
key-mgmt=wpa-psk
psk=${WIFI_PASS}

[ipv4]
method=auto

[ipv6]
method=auto
WIFI
chmod 600 /etc/NetworkManager/system-connections/${WIFI_SSID}.nmconnection

### --- LOCALE / TIME ---
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
ln -sf /usr/share/zoneinfo/Asia/Kathmandu /etc/localtime
hwclock --systohc

### --- HOSTNAME ---
echo "archlinux" > /etc/hostname
cat <<HOSTS > /etc/hosts
127.0.0.1 localhost
::1       localhost
127.0.1.1 archlinux.localdomain archlinux
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

### --- DOTFILES SETUP ---
# Clone your repo as the user
sudo -u "$USER" git clone "$DOTFILES_REPO" "/home/$USER/dotfiles"

# Create standard config directories
sudo -u "$USER" mkdir -p "/home/$USER/.config/hypr"
sudo -u "$USER" mkdir -p "/home/$USER/.config/waybar"

# Copy the files explicitly to where Hyprland and Waybar expect them
sudo -u "$USER" cp "/home/$USER/dotfiles/hyprland.conf" "/home/$USER/.config/hypr/hyprland.conf" || true
sudo -u "$USER" cp "/home/$USER/dotfiles/hyprpaper.conf" "/home/$USER/.config/hypr/hyprpaper.conf" || true
sudo -u "$USER" cp "/home/$USER/dotfiles/config" "/home/$USER/.config/waybar/config" || true
sudo -u "$USER" cp "/home/$USER/dotfiles/style.css" "/home/$USER/.config/waybar/style.css" || true

### --- MKINITCPIO ---
# Standard modules for Intel/AMD
sed -i 's/^MODULES=.*/MODULES=(i915)/' /etc/mkinitcpio.conf
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
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=UUID=$ROOT_UUID rw quiet loglevel=3 rd.udev.log_level=3
ENTRY

### --- SERVICES ---
systemctl enable NetworkManager bluetooth power-profiles-daemon fstrim.timer
systemctl --global enable pipewire pipewire-pulse wireplumber

echo "INSTALLATION COMPLETE"
EOF

chmod +x /mnt/next.sh
arch-chroot /mnt /next.sh
rm /mnt/next.sh

echo "DONE. You can reboot now."
