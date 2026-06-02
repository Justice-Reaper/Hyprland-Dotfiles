# Artix Linux Installation Guide

## systemd → dinit Equivalences

| systemd | Function | We use | Package |
|---|---|---|---|
| systemd (PID 1) | Init + services | dinit | `dinit` |
| systemd-journald | Logs | syslog-ng | `syslog-ng-dinit` + `logrotate` + `cronie-dinit` |
| systemd-logind | Sessions, suspend | elogind | `elogind-dinit` |
| systemd-networkd | Network | NetworkManager | `networkmanager-dinit` |
| systemd-resolved | DNS | openresolv | `openresolv` |
| systemd-timesyncd | NTP time | chrony | `chrony-dinit` |
| systemd-udevd | Devices | eudev | `eudev` |
| systemd-boot | Bootloader | GRUB | `grub` |
| systemd-tmpfiles | Temp dirs | etmpfiles | `etmpfiles` |
| systemd-cron/timers | Scheduled tasks | cronie | `cronie-dinit` |
| systemd --user | User services | turnstile | `turnstile-dinit` |
| pipewire user svc | Audio | pipewire | `pipewire-dinit` + `wireplumber-dinit` |
| display manager | Graphical login | sddm | `sddm-dinit` |
| bluetooth | Bluetooth | bluetoothd | `bluez-dinit` |
| systemd-homed | User accounts | /etc/passwd | nothing extra |
| systemd-hostnamed | Hostname | manual edit | `/etc/hostname` |
| systemd-localed | Locale/keyboard | manual edit | `/etc/locale.conf` + `/etc/vconsole.conf` |
| systemd-timedated | Timezone | manual edit | `ln -sf /usr/share/zoneinfo/...` |

## 1. Partitioning

### 1.1 Prepare the live ISO environment

```bash
su root
pacman -Syu
pacman -S gpm nano git
gpm -m /dev/input/mice -t imps2
```

Copy/paste with mouse
- Copy → select text with left button
- Paste → right button

### 1.2 Clone the guide from GitHub

```bash
cd /home/artix
git clone https://github.com/Justice-Reaper/Hyprland-Dotfiles.git
```

Open the guide in TTY 1

```bash
nano /home/artix/Hyprland-Dotfiles/README.md
```

Press `Ctrl+Alt+F2` for TTY 2 where you run commands
Switch back to TTY 1 with `Ctrl+Alt+F1`

> **IMPORTANT** The Artix installation USB is mounted at `/mnt`
> That's why we mount our partitions at `/media` instead of `/mnt`,
> to avoid conflicts with `fstabgen`

### 1.3 Identify the disk

```bash
lsblk
```

Set the variables with your disk names

```bash
DISK="/dev/nvme0n1"
EFI="/dev/nvme0n1p1"
ROOT="/dev/nvme0n1p2"
```

### 1.4 Create partitions (512MB EFI + rest btrfs)

Inside cfdisk
1. If there are existing partitions → select each one → `[ Delete ]` → repeat until all cleared
2. Select free space → `[ New ]` → type `512M` → Enter
3. With that partition → `[ Type ]` → select **EFI System**
4. Move down to remaining free space → `[ New ]` → Enter (use all)
5. The second partition appears as **Linux filesystem**, leave it as is
6. `[ Write ]` → type `yes` → `[ Quit ]`

```bash
cfdisk $DISK
```

### 1.5 Format the partitions

```bash
mkfs.fat -F32 $EFI
mkfs.btrfs -f $ROOT
```

### 1.6 Create the btrfs subvolumes

```bash
mkdir /media
mount $ROOT /media

btrfs subvolume create /media/@
btrfs subvolume create /media/@home
btrfs subvolume create /media/@var_cache
btrfs subvolume create /media/@var_log
btrfs subvolume create /media/@var_lib_libvirt
btrfs subvolume create /media/@snapshots

umount /media
```

### 1.7 Mount all subvolumes

```bash
mount -o rw,noatime,compress=zstd:1,subvol=@ $ROOT /media

mkdir /media/home
mkdir -p /media/boot/efi
mkdir /media/.snapshots
mkdir -p /media/var/cache
mkdir /media/var/log
mkdir -p /media/var/lib/libvirt

mount -o rw,noatime,compress=zstd:1,subvol=@home $ROOT /media/home
mount -o rw,noatime,compress=zstd:1,subvol=@var_cache $ROOT /media/var/cache
mount -o rw,noatime,compress=zstd:1,subvol=@var_log $ROOT /media/var/log
mount -o rw,noatime,compress=zstd:1,subvol=@var_lib_libvirt $ROOT /media/var/lib/libvirt
mount -o rw,noatime,compress=zstd:1,subvol=@snapshots $ROOT /media/.snapshots

mount $EFI /media/boot/efi
```

### 1.8 Apply NOCOW attributes

```bash
chattr +C /media/var/cache
chattr +C /media/var/log
chattr +C /media/var/lib/libvirt
```

### 1.9 Verify the subvolumes and mounts

```bash
btrfs subvolume list /media
mount | grep /media
lsattr -d /media/var/cache /media/var/log /media/var/lib/libvirt
```

## 2. System Configuration

### 2.1 Install the base system

```bash
basestrap /media base base-devel dinit elogind-dinit linux linux-firmware
```

### 2.2 Generate the fstab

```bash
fstabgen -U /media >> /media/etc/fstab
cat /media/etc/fstab
```

### 2.3 artix-chroot /media

Install the minimum packages needed to boot

```bash
artix-chroot /media
```

```bash
pacman -Syu
pacman -S git ttf-liberation xdg-user-dirs nano dbus-dinit networkmanager-dinit cronie-dinit hyprland kitty grub os-prober efibootmgr btrfs-progs snapper snap-pac grub-btrfs
```

### 2.4 Configure the system language

Uncomment `en_US.UTF-8 UTF-8`

```bash
nano /etc/locale.gen
```

```bash
locale-gen
printf 'LANG=en_US.UTF-8\nLC_COLLATE=C' > /etc/locale.conf
```

### 2.5 Configure the TTY keyboard layout

```bash
printf 'KEYMAP=es\nFONT=lat1-16\nFONT_MAP=8859-1_to_uni' > /etc/vconsole.conf
```

### 2.6 Configure /etc/hostname

```bash
echo 'artix' > /etc/hostname
```

### 2.7 Configure /etc/hostname

```bash
printf '127.0.0.1   localhost\n::1         localhost\n127.0.1.1   artix.localdomain artix' > /etc/hosts
```

### 2.7 Set the root password

```bash
passwd
```

### 2.8 Create your user

```bash
useradd -m -G wheel yourusername
passwd yourusername
```

### 2.9 Configure sudo for the wheel group

Find `# %wheel ALL=(ALL:ALL) ALL` and remove the `#`

```bash
nano /etc/sudoers
```

It should look like this

```
%wheel ALL=(ALL:ALL) ALL
```

Save with `Ctrl+O` → Enter → `Ctrl+X`

### 2.10 Configure snapper for btrfs snapshots

Snapper creates its own `.snapshots` subvolume, but we already have `@snapshots`, we need to replace it

```bash
umount /.snapshots
```

```bash
rmdir /.snapshots
```

```bash
snapper --no-dbus -c root create-config /
```

```bash
btrfs subvolume delete /.snapshots
```

```bash
mkdir /.snapshots
```

```bash
mount -o rw,noatime,compress=zstd:1,subvol=@snapshots /dev/nvme0n1p2 /.snapshots
```

```bash
chmod 750 /.snapshots
```

Find and change these values

```bash
nano /etc/snapper/configs/root
```

```
TIMELINE_CREATE="no"
NUMBER_CLEANUP="yes"
NUMBER_LIMIT="14"
NUMBER_LIMIT_IMPORTANT="7"
```

### 2.11 Install and configure GRUB

```bash
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg
```

### 2.12 Disable suspend when closing the laptop lid

```bash
sed -i 's/^#HandleLidSwitch=suspend/HandleLidSwitch=ignore/' /etc/elogind/logind.conf
sed -i 's/^#HandleLidSwitchExternalPower=suspend/HandleLidSwitchExternalPower=ignore/' /etc/elogind/logind.conf
sed -i 's/^#HandleLidSwitchDocked=ignore/HandleLidSwitchDocked=ignore/' /etc/elogind/logind.conf
sed -i 's/^#LidSwitchIgnoreInhibited=yes/LidSwitchIgnoreInhibited=yes/' /etc/elogind/logind.conf
```

### 2.13 Exit chroot and reboot

```bash
exit
reboot
```

### 2.14 After the first reboot

The system is now installed, you can remove the Artix installation USB

```bash
sudo dinitctl enable NetworkManager
sudo dinitctl start NetworkManager
```

### 2.15 Clone the dotfiles repository

```bash
cd /home/yourusername/Desktop
git clone https://github.com/Justice-Reaper/Hyprland-Dotfiles.git
```

### 2.16 Apply the Hyprland dotfiles

```bash
cd /home/yourusername/Desktop/Hyprland-Dotfiles
grep -rl 'justice-reaper' . | xargs sed -i 's/justice-reaper/yourusername/g'
```

```bash
cd Hyprland-Dotfiles
nano README.md
```

### 2.17 Create default user dirs

```bash
xdg-user-dirs-update
```

### 2.18 Start hyprland

```bash
start-hyprland
```

### 2.19 Configure automatic snapshot on boot

```bash
su root -c "EDITOR=nano crontab -e"
```

Add this line

```
@reboot snapper list | grep -q "$(date +%Y-%m-%d)" || snapper create -d "Boot" -c number --userdata "important=yes"
```

This creates a snapshot marked as "important" only once per day on the first boot, if you reboot multiple times, it won't create duplicates

| Type | When created | Limit | Who does it |
|---|---|---|---|
| Normal (pre/post) | When installing/removing with pacman | 14 | snap-pac |
| Important | On PC boot | 7 | cronie (@reboot) |

Save with `Ctrl+O` → Enter → `Ctrl+X`

### 2.20 Configure the repositories

Verify that Artix repos are enabled (no `#` in front), if any are commented, uncomment them

```bash
sudo nano /etc/pacman.conf
```

```
[system]
Include = /etc/pacman.d/mirrorlist

[world]
Include = /etc/pacman.d/mirrorlist

[galaxy]
Include = /etc/pacman.d/mirrorlist

[lib32]
Include = /etc/pacman.d/mirrorlist
```

Leave `gremlins` and `goblins` commented. NEVER enable `[core]` from Arch

### 2.21 Add the Arch repositories

```bash
sudo pacman -S artix-archlinux-support
sudo pacman-key --populate archlinux
```

Edit `/etc/pacman.conf` again and add at the end, AFTER the Artix repos

```bash
sudo nano /etc/pacman.conf
```

```

[extra]
Include = /etc/pacman.d/mirrorlist-arch

[multilib]
Include = /etc/pacman.d/mirrorlist-arch

```

### 2.22 Add the BlackArch repository

```bash
curl -O https://blackarch.org/strap.sh
echo 00688950aaf5e5804d2abebb8d3d3ea1d28525ed strap.sh | sha1sum -c
sudo chmod +x strap.sh
sudo ./strap.sh
rm strap.sh
sudo pacman -Syu
```

### 2.23 Optimize the mirrors based on your location

```bash
pacman -S rate-mirrors
```

```bash
rate-mirrors artix | sudo tee /etc/pacman.d/mirrorlist
rate-mirrors arch | sudo tee /etc/pacman.d/mirrorlist-arch
rate-mirrors blackarch | sudo tee /etc/pacman.d/blackarch-mirrorlist
```

### 2.24 Install all packages

```bash
sudo pacman -Syu
sudo pacman -S openresolv chrony-dinit syslog-ng-dinit logrotate etmpfiles
sudo pacman -S cronie-dinit turnstile-dinit pipewire-dinit wireplumber-dinit pipewire-pulse pipewire-jack xorg-server sddm-dinit
sudo pacman -S bluez-dinit bluez-utils inter-font noto-fonts noto-fonts-emoji noto-fonts-cjk linux-headers vulkan-radeon man-db rust zsh
sudo pacman -S xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-desktop-portal qt5-wayland qt6-wayland hyprland-qt-support libnotify
sudo pacman -S ntfs-3g exfatprogs dosfstools unzip plocate wget blueman nm-connection-editor thunar gvfs tumbler thunar-volman nwg-look papirus-icon-theme
sudo pacman -S waybar hyprpaper rofi mako btop fastfetch jq lsd bat fzf grim slurp swappy wl-clipboard wl-clip-persist xf86-input-libinput pavucontrol
sudo pacman -S zsh-autosuggestions zsh-completions zsh-syntax-highlighting 
```

### 2.25 Install paru as AUR helper

```bash
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd ..
rm -rf paru
```

### 2.26 Install AUR packages

```bash
paru -S themix-full-git swaylock-effects windows-10-cursor google-chrome zsh-sudo wl-gammarelay-rs cmd-polkit-git acp6x-victus-16e1-dkms
```

### 2.27 Enable and start all services

```bash
sudo dinitctl enable dbus
sudo dinitctl enable elogind
sudo dinitctl enable chrony
sudo dinitctl enable syslog-ng
sudo dinitctl enable cronie
sudo dinitctl enable turnstiled
sudo dinitctl enable bluetoothd
sudo dinitctl enable sddm
```

```bash
sudo dinitctl start dbus
sudo dinitctl start elogind
sudo dinitctl start chrony
sudo dinitctl start syslog-ng
sudo dinitctl start cronie
sudo dinitctl start turnstiled
sudo dinitctl start bluetoothd
sudo dinitctl start sddm
```

### 2.28 Configure zshrc and Powerlevel10k

```bash
mv p10k.zsh .p10k.zsh
cp zshrc/zshrc-powerlevel10k-user .zshrc
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/yourusername/powerlevel10k
cp .p10k.zsh /home/yourusername
cp .zshrc /home/yourusername
cp zshrc/zshrc-powerlevel10k-root .zshrc
sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /root/powerlevel10k
sudo cp .p10k.zsh /root
sudo cp .zshrc /root
sudo ln -s -f /home/yourusername/.p10k.zsh /root/.p10k.zsh
```

### 2.29 Set zsh as default shell for user and root

```bash
chsh -s /usr/bin/zsh
sudo chsh -s /usr/bin/zsh root
```

### 2.30 Copy the udev rules

```bash
sudo cp udev/rules.d/* /etc/udev/rules.d/
```

### 2.31 Copy the pacman hooks

```bash
sudo cp hooks/* /etc/pacman.d/
```

### 2.32 Copy the xorg configuration

```bash
sudo cp xorg.conf.d/* /etc/X11/xorg.conf.d/
```

### 2.33 Configure the rofi launcher filter

```bash
mkdir -p ~/.local/share/applications
find /usr/share/applications -name "*.desktop" | ~/.config/rofi/launcher/filter.sh
sudo cp rofi-launcher-filter.hook /etc/pacman.d/hooks
sudo chmod 644 /etc/pacman.d/hooks/rofi-launcher-filter.hook
```

### 2.34 Fix disk mounting in Thunar

```bash
sudo cp mount_options.conf /etc/udisks2
sudo chmod 644 /etc/udisks2/mount_options.conf
```

## 3. How to recover the system when everything breaks

### 3.1 If GRUB works

Reboot → in GRUB select `Artix Linux snapshots` → choose the snapshot you want to restore → it boots in read-only mode → verify it works

### 3.2 If GRUB doesn't work (live USB)

Boot from the Artix USB

```bash
su root
```

Mount the btrfs partition WITHOUT a subvolume (top level)

```bash
mount /dev/nvme0n1p2 /mnt
```

View available snapshots

```bash
ls /mnt/@snapshots/
```

View the description of each snapshot

```bash
for dir in /mnt/@snapshots/*/; do echo "=== $(basename $dir) ==="; grep -o '<description>.*</description>' "$dir/info.xml"; done
```

Move the broken system and replace with the good snapshot (change NUMBER to the one you choose)

```bash
mv /mnt/@ /mnt/@broken
btrfs subvolume snapshot /mnt/@snapshots/NUMBER/snapshot /mnt/@
```

If GRUB is also broken, fix it with chroot

```bash
mount -o rw,noatime,compress=zstd:1,subvol=@ /dev/nvme0n1p2 /media
mount /dev/nvme0n1p1 /media/boot/efi
artix-chroot /media
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg
exit
```

Reboot

```bash
reboot
```

Once the system works, delete the broken subvolume

```bash
sudo mount /dev/nvme0n1p2 /mnt
sudo btrfs subvolume delete /mnt/@broken
sudo umount /mnt
```
