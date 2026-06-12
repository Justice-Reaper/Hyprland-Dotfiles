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

### Prepare the live ISO environment

```bash
su root
pacman -Syu
pacman -S gpm nano git
gpm -m /dev/input/mice -t imps2
```

Copy/paste with mouse
- Copy → select text with left button
- Paste → right button

### Clone the guide from GitHub

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

### Identify the disk

```bash
lsblk
```

Set the variables with your disk names

```bash
DISK="/dev/nvme0n1"
EFI="/dev/nvme0n1p1"
ROOT="/dev/nvme0n1p2"
```

### Create partitions (512MB EFI + rest btrfs)

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

### Format the partitions

```bash
mkfs.fat -F32 $EFI
mkfs.btrfs -f $ROOT
```

### Create the btrfs subvolumes

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

### Mount all subvolumes

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

### Apply NOCOW attributes

```bash
chattr +C /media/var/cache
chattr +C /media/var/log
chattr +C /media/var/lib/libvirt
```

### Verify the subvolumes and mounts

```bash
btrfs subvolume list /media
mount | grep /media
lsattr -d /media/var/cache /media/var/log /media/var/lib/libvirt
```

## 2. System Configuration

### Install the base system

```bash
basestrap /media base base-devel dinit elogind-dinit linux linux-firmware
```

### Generate the fstab

```bash
fstabgen -U /media >> /media/etc/fstab
cat /media/etc/fstab
```

### artix-chroot /media

Install the minimum packages needed to boot

```bash
artix-chroot /media
```

```bash
pacman -Syu
pacman -S git ttf-liberation xdg-user-dirs nano dbus-dinit networkmanager-dinit cronie-dinit hyprland kitty grub os-prober efibootmgr btrfs-progs snapper snap-pac grub-btrfs
```

### Configure the system timezone

```bash
sudo ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime
```

### Configure the system language

Uncomment `en_US.UTF-8 UTF-8`

```bash
nano /etc/locale.gen
```

```bash
locale-gen
printf 'LANG=en_US.UTF-8\nLC_COLLATE=C' > /etc/locale.conf
```

### Configure the TTY keyboard layout

```bash
printf 'KEYMAP=es\nFONT=lat1-16\nFONT_MAP=8859-1_to_uni' > /etc/vconsole.conf
```

### Configure /etc/hostname

```bash
echo 'artix' > /etc/hostname
```

### Configure /etc/hosts

```bash
printf '127.0.0.1   localhost\n::1         localhost\n127.0.1.1   artix.localdomain artix' > /etc/hosts
```

### Set the root password

```bash
passwd
```

### Create your user

```bash
useradd -m -G wheel,storage justice-reaper
passwd justice-reaper
```

### Configure sudo for the wheel group

Find `# %wheel ALL=(ALL:ALL) ALL` and remove the `#`

```bash
nano /etc/sudoers
```

It should look like this

```
%wheel ALL=(ALL:ALL) ALL
```

Save with `Ctrl+O` → Enter → `Ctrl+X`

### Configure snapper for btrfs snapshots

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
NUMBER_LIMIT="30"
NUMBER_LIMIT_IMPORTANT="15"
```

### Install and configure GRUB

```bash
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=grub
grub-mkconfig -o /boot/grub/grub.cfg
```

### Disable suspend when closing the laptop lid

```bash
sed -i 's/^#HandleLidSwitch=suspend/HandleLidSwitch=ignore/' /etc/elogind/logind.conf
sed -i 's/^#HandleLidSwitchExternalPower=suspend/HandleLidSwitchExternalPower=ignore/' /etc/elogind/logind.conf
sed -i 's/^#HandleLidSwitchDocked=ignore/HandleLidSwitchDocked=ignore/' /etc/elogind/logind.conf
sed -i 's/^#LidSwitchIgnoreInhibited=yes/LidSwitchIgnoreInhibited=yes/' /etc/elogind/logind.conf
```

### Exit chroot and reboot

```bash
exit
reboot
```

### After the first reboot

The system is now installed, you can remove the Artix installation USB

```bash
sudo dinitctl enable NetworkManager
sudo dinitctl start NetworkManager
```

### Create default user dirs

```bash
xdg-user-dirs-update
```

### Clone the dotfiles repository

```bash
cd /home/justice-reaper/Downloads
git clone https://github.com/Justice-Reaper/Hyprland-Dotfiles.git
```

### Apply the Hyprland dotfiles

```bash
cd /home/justice-reaper/Downloads/Hyprland-Dotfiles
grep -rl 'justice-reaper' . | xargs sed -i 's/justice-reaper/yourUsername/g'
```

### Start hyprland

```bash
start-hyprland
```

Open the guide

```bash
nano README.md
```

### Configure automatic snapshots at boot and daily snapshot cleanup

```bash
su root -c "EDITOR=nano crontab -e"
```

Add this line

```
@reboot snapper list | grep -q "$(date +%Y-%m-%d)" || snapper create -d "Boot" -c number --userdata "important=yes"
@daily snapper -c root cleanup number
```

This creates a snapshot marked as "important" only once per day on the first boot, if you reboot multiple times, it won't create duplicates

| Type | When created | Limit | Who does it |
|---|---|---|---|
| Normal (pre/post) | When installing/removing with pacman | 14 | snap-pac |
| Important | On PC boot | 7 | cronie (@reboot) |

Save with `Ctrl+O` → Enter → `Ctrl+X`

### Configure the repositories

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

### Add the Arch repositories

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

### Add the BlackArch repository

```bash
curl -O https://blackarch.org/strap.sh
echo 00688950aaf5e5804d2abebb8d3d3ea1d28525ed strap.sh | sha1sum -c
sudo chmod +x strap.sh
sudo ./strap.sh
rm strap.sh
sudo pacman -Syu
```

### Optimize the mirrors based on your location

```bash
su root
pacman -S rate-mirrors
```

```bash
su justice-reaper -c "rate-mirrors artix" | tee /etc/pacman.d/mirrorlist
su justice-reaper -c "rate-mirrors arch" | tee /etc/pacman.d/mirrorlist-arch
su justice-reaper -c "rate-mirrors blackarch" | tee /etc/pacman.d/blackarch-mirrorlist
```

### Install all packages

```bash
sudo pacman -Syu
sudo pacman -S openresolv chrony-dinit syslog-ng-dinit logrotate etmpfiles pipewire-pulse-dinit pipewire-alsa obsidian ttf-hack-nerd
sudo pacman -S cronie-dinit turnstile-dinit pipewire-dinit wireplumber-dinit pipewire-jack xorg-server sddm-dinit pkgfile pavucontrol
sudo pacman -S bluez-dinit bluez-utils inter-font noto-fonts noto-fonts-emoji noto-fonts-cjk linux-headers vulkan-radeon man-db rust zsh
sudo pacman -S xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-desktop-portal qt5-wayland qt6-wayland hyprland-qt-support libnotify
sudo pacman -S ntfs-3g exfatprogs dosfstools unzip plocate wget blueman nm-connection-editor gvfs nemo xed nwg-look jre21-openjdk xdg-utils
sudo pacman -S waybar hyprpaper rofi dunst btop fastfetch jq lsd bat fzf grim flameshot wl-clipboard wl-clip-persist xf86-input-libinput
sudo pacman -S zsh-autosuggestions zsh-completions zsh-syntax-highlighting celluloid openbsd-netcat qt5ct qt6ct pix 
```

### Install paru as AUR helper

```bash
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd ..
rm -rf paru
```

### Install AUR packages

```bash
paru -S ix-full-git windows-10-cursor google-chrome zsh-sudo wl-gammarelay-rs cmd-polkit-git acp6x-victus-16e1-dkms nomacs
```

### Create services

```bash
sudo cp services/grub-btrfsd /etc/dinit.d
```

### Enable and start all services

```bash
su justice-reaper
dinitctl --user enable pipewire
dinitctl --user enable wireplumber
dinitctl --user enable pipewire-pulse
```

```bash
su root
dinitctl enable dbus
dinitctl enable elogind
dinitctl enable chrony
dinitctl enable syslog-ng
dinitctl enable cronie
dinitctl enable turnstiled
dinitctl enable bluetoothd
dinitctl enable sddm
dinitctl enable grub-btrfsd
```

### Enable grub-btrfs 

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

### Configure plocate for bind mounts

Find and change this value

```bash
sudo nano /etc/updatedb.conf
```

```bash
PRUNE_BIND_MOUNTS = "no"
```

```bash
sudo updatedb
```

### Update pkgfile database

```bash
sudo pkgfile --update
```

### Configure X11

```bash
sudo cp -r X11/* /etc/X11/xorg.conf.d
```

### Install Burp Suite Professional

```bash
su root
cp -r burpsuite-professional/burpsuite-professional /opt
cd /opt/burpsuite-professional
```

Download the latest Burp Suite Professional JAR here https://portswigger.net/burp/releases#professional and copy it

```bash
cp /home/justice-reaper/Downloads/burpsuite_desktop_v2026.4.3.jar /opt/burpsuite-professional
```

We run this command, and in the part where it says jarFileName, we need to put the name of the downloaded JAR. In this case, it would be burpsuite_desktop_v2026.4.3.jar

```bash
echo "java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:$(pwd)/loader.jar -noverify -jar $(pwd)/jarFileName &" > /usr/bin/burpsuitepro
chmod 755 /usr/bin/burpsuitepro
```

List the available Java versions

```bash
archlinux-java status
```

Set Java 21 as the default version

```bash
sudo archlinux-java set java-21-openjdk
```

Activate Burp Suite Professional

```bash
su justice-reaper
java -jar loader.jar &
burpsuitepro
```

Copy the Burp Suite Professional icons

```bash
sudo cp burpsuite-professional/burpsuite-professional-icons/16x16/burpsuitepro.png /usr/share/icons/hicolor/16x16/apps/burpsuitepro.png
sudo cp burpsuite-professional/burpsuite-professional-icons/24x24/burpsuitepro.png /usr/share/icons/hicolor/24x24/apps/burpsuitepro.png
sudo cp burpsuite-professional/burpsuite-professional-icons/32x32/burpsuitepro.png /usr/share/icons/hicolor/32x32/apps/burpsuitepro.png
sudo cp burpsuite-professional/burpsuite-professional-icons/48x48/burpsuitepro.png /usr/share/icons/hicolor/48x48/apps/burpsuitepro.png
sudo cp burpsuite-professional/burpsuite-professional-icons/128x128/burpsuitepro.png /usr/share/icons/hicolor/128x128/apps/burpsuitepro.png
sudo cp burpsuite-professional/burpsuite-professional-icons/256x256/burpsuitepro.png /usr/share/icons/hicolor/256x256/apps/burpsuitepro.png
sudo cp burpsuite-professional/burpsuite-professional-icons/512x512/burpsuitepro.png /usr/share/icons/hicolor/512x512/apps/burpsuitepro.png
sudo cp burpsuite-professional/burpsuite-professional-icons/scalable/burpsuitepro.svg /usr/share/icons/hicolor/scalable/apps/burpsuitepro.svg
```

Copy the Burp Suite Professional shortcut

```bash
sudo cp burpsuite-professional/burpsuitepro.desktop /usr/share/applications
cp burpsuite-professional/burpsuitepro.desktop /home/justice-reaper/.local/share/applications
```

### Apply Tokyo Night Dark theme for user justice-reaper

Configure the theme for GTK3

```bash
mkdir -p /home/justice-reaper/.themes/oomox-tokyo-night-dark
cp -r oomox-themes/gtk3/* /home/justice-reaper/.themes/oomox-tokyo-night-dark
```

Configure the theme for GTK4

```bash
mkdir -p /home/justice-reaper/.themes/oomox-tokyo-night-dark/gtk-4.0
mkdir -p /home/justice-reaper/.config/gtk-4.0
cp oomox-themes/gtk4/gtk.css /home/justice-reaper/.themes/oomox-tokyo-night-dark/gtk-4.0
ln -sf /home/justice-reaper/.themes/oomox-tokyo-night-dark/gtk-4.0/gtk.css /home/justice-reaper/.config/gtk-4.0/gtk.css
```

Configure the theme for Qt5 and Qt6

```bash
mkdir -p /home/justice-reaper/.config/qt5ct/colors /home/justice-reaper/.config/qt6ct/colors
cp oomox-themes/qt5ct/colors/oomox-tokyo-night-dark.conf /home/justice-reaper/.config/qt5ct/colors
cp oomox-themes/qt6ct/colors/oomox-tokyo-night-dark.conf /home/justice-reaper/.config/qt6ct/colors
```

Configure the icons

```bash
mkdir -p /home/justice-reaper/.icons/oomox-tokyo-night-dark
cp -r oomox-themes/icons/* /home/justice-reaper/.icons/oomox-tokyo-night-dark
```

Run qt5ct qt6ct and set these options

| Option | Value |
|--------|-------|
| Style | Fusion |
| Color Scheme | oomox-tokyo-night-dark |
| Standard Dialogs | gtk3 |
| Font General | Inter, 10 |
| Font Fixed Width | Monospace, 10 |
| Icon Theme | oomox-tokyo-night-dark |

```bash
qt5ct
qt6ct
```

Run nwg-look and set these options

| Option | Value |
|--------|-------|
| Widget Theme | oomox-tokyo-night-dark |
| Icon Theme | oomox-tokyo-night-dark |
| Default Font | Inter Regular, 11 |
| Color Scheme | prefer-dark |
| Cursor Theme | Windows-10-Alt-Light |

```bash
nwg-look
```

### Apply Tokyo Night Dark theme for user root

Configure the theme for GTK3

```bash
su root
mkdir -p /root/.themes/oomox-tokyo-night-dark
cp -r oomox-themes/gtk3/* /root/.themes/oomox-tokyo-night-dark
```

Configure the theme for GTK4

```bash
mkdir -p /root/.themes/oomox-tokyo-night-dark/gtk-4.0
mkdir -p /root/.config/gtk-4.0
cp oomox-themes/gtk4/gtk.css /root/.themes/oomox-tokyo-night-dark/gtk-4.0
ln -sf /root/.themes/oomox-tokyo-night-dark/gtk-4.0/gtk.css /root/.config/gtk-4.0/gtk.css
```

Configure the theme for Qt5 and Qt6

```bash
mkdir -p /root/.config/qt5ct/colors /root/.config/qt6ct/colors
cp oomox-themes/qt5ct/colors/oomox-tokyo-night-dark.conf /root/.config/qt5ct/colors
cp oomox-themes/qt6ct/colors/oomox-tokyo-night-dark.conf /root/.config/qt6ct/colors
```

Configure the icons

```bash
mkdir -p /root/.icons/oomox-tokyo-night-dark
cp -r oomox-themes/icons/* /root/.icons/oomox-tokyo-night-dark
```

Run qt5ct qt6ct and set these options

| Option | Value |
|--------|-------|
| Style | Fusion |
| Color Scheme | oomox-tokyo-night-dark |
| Standard Dialogs | gtk3 |
| Font General | Inter, 10 |
| Font Fixed Width | Monospace, 10 |
| Icon Theme | oomox-tokyo-night-dark |

```bash
qt5ct
qt6ct
```

Run nwg-look and set these options

| Option | Value |
|--------|-------|
| Widget Theme | oomox-tokyo-night-dark |
| Icon Theme | oomox-tokyo-night-dark |
| Default Font | Inter Regular, 11 |
| Color Scheme | prefer-dark |
| Cursor Theme | Windows-10-Alt-Light |

```bash
nwg-look
```

If there are any issues, you can recreate the theme by following the steps in oomox-user-preset/RECREATE-OOMOX-THEME.md

### Add custom tools

```bash
chmod 755 bin/*
sudo cp bin/* /usr/bin
```

### Set waybar icon font

```bash
sudo cp -r fonts /usr/local/share
```

### Set system default terminal

```bash
gsettings set org.cinnamon.desktop.default-applications.terminal exec kitty
```

### Configure zshrc and Powerlevel10k

```bash
mv p10k.zsh .p10k.zsh
cp zshrc/zshrc-powerlevel10k-user .zshrc
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /home/justice-reaper/powerlevel10k
cp .p10k.zsh /home/justice-reaper
cp .zshrc /home/justice-reaper
cp zshrc/zshrc-powerlevel10k-root .zshrc
sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /root/powerlevel10k
sudo cp .p10k.zsh /root
sudo cp .zshrc /root
sudo ln -s -f /home/justice-reaper/.p10k.zsh /root/.p10k.zsh
```

### Copy configuration files

```bash
mv config .config
cp -r .config /home/justice-reaper
```

### Configure sddm and quickshell

Follow these steps to install sddm as display manager and quickshell as lockscreen [https://github.com/Darkkal44/qylock.git](https://github.com/Darkkal44/qylock.git). It is recommended to use the pixel-cyberpunk or pixel-waterfall theme

### Set zsh as default shell for user and root

```bash
chsh -s /usr/bin/zsh
sudo chsh -s /usr/bin/zsh root
```

### Copy udev rules

```bash
cp rules/* /etc/udev/rules.d/
```

### Copy the pacman hooks

```bash
sudo cp -r hooks /etc/pacman.d
```

### Copy the xorg configuration

```bash
sudo cp X11/* /etc/X11/xorg.conf.d
```

### Configure the rofi launcher filter

```bash
mkdir -p /home/justice-reaper/.local/share/applications
find /usr/share/applications -name "*.desktop" | /home/justice-reaper/.config/rofi/filters/sync-desktop.sh
/home/justice-reaper/.config/rofi/filters/desktop-cache.sh
```

## 3. How to recover the system when everything breaks

### If GRUB works

Reboot → in GRUB select `Artix Linux snapshots` → choose the snapshot you want to restore → it boots in read-only mode → verify it works

### If GRUB doesn't work (live USB)

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
