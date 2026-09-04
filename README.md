# Preview

![Preview 1](/preview/preview-1.png)

![Preview 2](/preview/preview-2.png)

![Preview 3](/preview/preview-3.png)

![Preview 4](/preview/preview-4.png)

![Preview 5](/preview/preview-5.png)

![Preview 6](/preview/preview-6.png)

![Preview 7](/preview/preview-7.png)

![Preview 8](/preview/preview-8.png)

# Donations
Would you like to support the continued development of this project? You can contribute with a small donation by clicking the button below

[![Thanks for all your support](https://img.buymeacoffee.com/button-api/?text=Thanks%20for%20all%20your%20support&emoji=☕&slug=justiceReaper&button_colour=FF5F5F&font_colour=ffffff&font_family=Lato&outline_colour=000000&coffee_colour=FFDD00)](https://www.buymeacoffee.com/justiceReaper)

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
git clone https://github.com/Justice-Reaper/Hyprland-Artix-Linux-Dotfiles.git
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

### Install the minimum packages needed to boot

 Enter the chroot environment
 
```bash
artix-chroot /media
```

Update the system and install base packages

```bash
pacman -Syu
pacman -S inotify-tools git ttf-liberation xdg-user-dirs nano dbus-dinit networkmanager-dinit cronie-dinit hyprland kitty grub os-prober efibootmgr btrfs-progs snapper snap-pac grub-btrfs zramen-dinit
```

### Configure the wifi regulatory domain  

Uncomment `WIRELESS_REGDOM="ES"`

```bash
nano /etc/conf.d/wireless-regdom
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
useradd -m -G wheel,storage,video justice-reaper
passwd justice-reaper
```

### Configure sudo for the wheel group

Uncomment %wheel ALL=(ALL:ALL) ALL

```bash
nano /etc/sudoers
```

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
NUMBER_LIMIT="60"
NUMBER_LIMIT_IMPORTANT="20"
```

### Install and configure GRUB

Change GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet" to GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet amdgpu.dcdebugmask=0x10" to disable AMD Panel Self Refresh (PSR) and avoid random compositor freezes on Rembrandt/RDNA2 eDP panels

```bash
nano /etc/default/grub
```

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
```

### Create default user dirs

```bash
xdg-user-dirs-update
```

### Start hyprland

```bash
start-hyprland
```
### Clone the dotfiles repository and open the guide

```bash
cd /home/justice-reaper/Downloads
git clone https://github.com/Justice-Reaper/Hyprland-Artix-Linux-Dotfiles.git
```

```bash
nano README.md
```

### Replace the hardcoded username in the dotfiles

```bash
cd /home/justice-reaper/Downloads/Hyprland-Dotfiles
grep -rl 'justice-reaper' . | xargs sed -i 's/justice-reaper/yourUsername/g'
```

### Give execution permissions to all the files that need it

```bash
chmod +x bin/*
chmod +x generate-icons-font/*.sh
chmod +x dinit-overlayfs/*.sh
chmod +x sddm/sddm-xsetup
chmod +x hooks/snap-pac-wrapper
chmod +x config/rofi/filters/*.sh
chmod +x config/rofi/launcher/*.sh
chmod +x config/rofi/manager/*.sh
chmod +x config/rofi/polkit-agent/rofi-polkit-agent
chmod +x config/rofi/power-menu/*.sh
chmod +x config/rofi/scope-manager/*.sh
chmod +x config/rofi/tray/*.sh
chmod +x config/rofi/vault/*.sh
chmod +x config/touchpad-control/*.sh
chmod +x config/usb-sound/scripts/*.sh
chmod +x config/waybar/scripts/*.sh
```

### Replace the hardcoded backlight device in the dotfiles

List your backlight device and save its name in a variable

```bash
backlight=$(ls /sys/class/backlight)
```

Replace the hardcoded amdgpu_bl2 with your device

```bash
cd /home/justice-reaper/Downloads/Hyprland-Dotfiles
grep -rl 'amdgpu_bl2' . | xargs sed -i "s/amdgpu_bl2/$backlight/g"
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
| Normal (pre/post) | When installing/removing with pacman | 60 | snap-pac |
| Important | On PC boot | 20 | cronie (@reboot) |

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
sudo pacman -Sy
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
pacman -Syu
pacman -S openresolv chrony-dinit syslog-ng-dinit logrotate etmpfiles pipewire-pulse-dinit pipewire-alsa ttf-hack-nerd xdg-utils
pacman -S sudo turnstile-dinit pipewire-dinit wireplumber-dinit pipewire-jack xorg-server sddm-dinit pkgfile pavucontrol firefox
pacman -S bluez-dinit bluez-utils inter-font noto-fonts noto-fonts-emoji noto-fonts-cjk linux-headers vulkan-radeon man-db rust
pacman -S xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-desktop-portal qt5-wayland qt6-wayland hyprland-qt-support libnotify
pacman -S ntfs-3g exfatprogs dosfstools unzip plocate wget blueman nm-connection-editor gvfs nemo xed engrampa jre21-openjdk zsh
pacman -S waybar hyprpaper rofi dunst btop fastfetch jq lsd bat fzf grim flameshot wl-clipboard wl-clip-persist xf86-input-libinput
pacman -S zsh-autosuggestions zsh-completions zsh-syntax-highlighting celluloid qt5ct qt6ct gthumb net-tools nwg-look brightnessctl
pacman -S libvirt-dinit qemu-desktop virt-manager dnsmasq edk2-ovmf swtpm dmidecode libosinfo guestfs-tools qrencode wireless-regdb
pacman -S obsidian seclists python-html2text nmap openbsd-netcat exiftool netexec kerbrute windapsearch pycharm-community-edition
pacman -S ffuf arp-scan perl-text-csv perl-lwp-protocol-https sqlmap python-pwntools wcvs katana-pd bind moreutils smbclient phpggc
pacman -S jdk8-openjdk ysoserial tinja sstimap torbrowser-launcher
exit
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

> **Note:** If you don't have an HP Victus 16-e1, don't install the `acp6x-victus-16e1-dkms` package

```bash
paru -S themix-full-git windows-10-cursor google-chrome zsh-sudo wl-gammarelay-rs cmd-polkit-git acp6x-victus-16e1-dkms vesktop hyprland-minimizer-git
```

### Create services

```bash
sudo cp services/grub-btrfsd /etc/dinit.d
```

### Enable and start all services

```bash
su root
dinitctl enable zramen
dinitctl enable dbus
dinitctl enable elogind
dinitctl enable chrony
dinitctl enable syslog-ng
dinitctl enable cronie
dinitctl enable turnstiled
dinitctl enable bluetoothd
dinitctl enable sddm
dinitctl enable grub-btrfsd
dinitctl enable libvirtd
```

```bash
su justice-reaper
dinitctl --user enable pipewire
dinitctl --user enable wireplumber
dinitctl --user enable pipewire-pulse
```

### Copy configuration files

```bash
mv config .config
cp -r .config /home/justice-reaper
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

### Set zsh as default shell for user and root

```bash
chsh -s /usr/bin/zsh
sudo chsh -s /usr/bin/zsh root
```

### Set a wallpaper

```bash
cp -r Wallpapers /home/justice-reaper
```

### Copy the pacman hooks

```bash
sudo mkdir /etc/pacman.d/hooks
sudo cp hooks/snap-pac-wrapper /usr/local/lib
sudo cp hooks/*.hook /etc/pacman.d/hooks
```

### Configure the rofi launcher filter

```bash
mkdir -p /home/justice-reaper/.local/share/applications
find /usr/share/applications -name "*.desktop" | /home/justice-reaper/.config/rofi/filters/sync-desktop.sh
```

### Disable Bluetooth auto-enable at boot

Change #AutoEnable=true to AutoEnable=false to keep Bluetooth off at boot

```bash
sudo nano /etc/bluetooth/main.conf
```

### Configure zram

Change #ZRAM_SIZE=100 to ZRAM_SIZE=50 to set zram to 50% of RAM

```bash
sudo nano /etc/dinit.d/config/zramen.conf
```

### Configure syslog-ng

Uncomment `filter(f_kernel);`, `destination(d_kernel);`, `filter(f_err);` and `destination(d_errors);` to enable kernel and error logging

```bash
sudo nano /etc/syslog-ng/syslog-ng.conf
```

### Enable grub-btrfs 

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### Build the initramfs on disk instead of tmpfs

Change #default_options="--splash /usr/share/systemd/bootctl/splash-arch.bmp" to default_options="--builddir /var/tmp" 

```bash
sudo nano /etc/mkinitcpio.d/linux.preset
```

### Configure grub-btrfs-overlayfs for clean snapshot boot

When booting a read-only snapshot from GRUB, dinit services `root-ro` and `early-root-rw.target` try to remount `/` which fails on modern kernels (6.12+) with `overlay: No changes allowed in reconfigure`. This causes all dependent services to fail with exit code 32.

The fix has two parts: (1) the `grub-btrfs-overlayfs` mkinitcpio hook mounts a temporary RAM layer on top of the read-only snapshot, and (2) dinit service overrides detect when root is overlayfs and skip the unnecessary remount.

Add the `overlay` module and `grub-btrfs-overlayfs` hook to `/etc/mkinitcpio.conf`

```bash
sudo sed -i 's/^MODULES=()/MODULES=(overlay)/' /etc/mkinitcpio.conf
sudo sed -i 's/fsck)/fsck grub-btrfs-overlayfs)/' /etc/mkinitcpio.conf
```

Verify it looks correct

```bash
grep "^MODULES\|^HOOKS" /etc/mkinitcpio.conf
```

Expected output

```
MODULES=(overlay)
HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck grub-btrfs-overlayfs)
```

Install the dinit overlayfs wrapper scripts

```bash
sudo mkdir -p /usr/local/lib/dinit
sudo cp dinit-overlayfs/root-ro-overlay.sh /usr/local/lib/dinit/
sudo cp dinit-overlayfs/early-root-rw-overlay.sh /usr/local/lib/dinit/
```

Install the dinit service overrides

```bash
sudo cp dinit-overlayfs/root-ro /etc/dinit.d/
sudo cp dinit-overlayfs/early-root-rw.target /etc/dinit.d/
```

Regenerate the initramfs and update GRUB

```bash
sudo mkinitcpio -P
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### Configure plocate for bind mounts

If the line `PRUNE_BIND_MOUNTS = "yes"` exists, change it to `PRUNE_BIND_MOUNTS = "no"`. If it does not exist, add `PRUNE_BIND_MOUNTS = "no"` at the top of the file

```bash
sudo nano /etc/updatedb.conf
```

Rebuild the database

```bash
sudo updatedb
```

### Update pkgfile database

```bash
sudo pkgfile --update
```

### Configure X11


Get your touchpad id

```bash
grep -i touchpad /proc/bus/input/devices | sed -E 's/.*Name="(.*) [^ ]+".*/\1/'
```

Paste it into the `MatchProduct` line of `X11/98-touchpad.conf`, then copy the configs

```bash
sudo cp -r X11/* /etc/X11/xorg.conf.d
```

### Configure Qemu + KVM

Add user to the kvm and libvirt groups

```bash
sudo usermod -aG kvm,libvirt justice-reaper
```

Make sure AMD-V (SVM) is enabled in the BIOS/UEFI, then confirm the kernel exposes KVM

```bash
lscpu | grep -i virtualization
```

Optionally confirm the running kernel includes the KVM modules. `y` means KVM is built into the kernel, while `m` means it is available as a loadable kernel module. Either is fine

```bash
zgrep CONFIG_KVM /proc/config.gz
```

Verify the `kvm_amd` module is loaded and that the KVM device exists

```bash
lsmod | grep kvm
ls -l /dev/kvm
```

If the `kvm_amd` module is not loaded, load it

```bash
sudo modprobe kvm_amd
```

Grant access to members of the `libvirt` group through the unix socket instead of relying on a polkit agent by uncommenting `unix_sock_group = "libvirt"` and `unix_sock_rw_perms = "0770"`, and changing `#auth_unix_rw = "polkit"` to `auth_unix_rw = "none"`

```bash
sudo nano /etc/libvirt/libvirtd.conf
```

Make virsh and virt-manager default to the system connection instead of the per-user session. Uncomment this line `uri_default = "qemu:///system"`

```bash
sudo nano /etc/libvirt/libvirt.conf
```

Change `#user = "libvirt-qemu"` to `user = "justice-reaper"` and `#group = "libvirt-qemu"` to `group = "libvirt"` to run VMs as your own user

```bash
sudo nano /etc/libvirt/qemu.conf
```

Enable nested virtualization 

```bash
echo "options kvm_amd nested=1" | sudo tee /etc/modprobe.d/kvm-amd.conf
```

Start the default NAT network

```bash

sudo virsh net-autostart default
```

Run the libvirt host checker

```bash
virt-host-validate qemu
```

List domains through the system connection. This should succeed even with no VMs

```bash
virsh -c qemu:///system list --all
```

Windows ships no VirtIO drivers, so the fast paravirtualized disk and network devices are invisible during setup. Install `virtio-win` (`paru -S virtio-win`, lands in `/usr/share/virtio-win/`) or download `virtio-win.iso` from the Fedora repo, attach it as a second CD-ROM, and load the driver during installation

Install `spice-vdagent` inside the guest, not on the host, since the host SPICE support already comes with virt-manager

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
echo "java --add-opens=java.desktop/javax.swing=ALL-UNNAMED --add-opens=java.base/java.lang=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.tree=ALL-UNNAMED --add-opens=java.base/jdk.internal.org.objectweb.asm.Opcodes=ALL-UNNAMED -javaagent:/opt/burpsuite-professional/loader.jar -noverify -jar /opt/burpsuite-professional/jarFileName &" > /usr/local/bin/burpsuitepro
chmod 755 /usr/local/bin/burpsuitepro
```

List the available Java versions

```bash
archlinux-java status
```

Set Java 21 as the default version

```bash
archlinux-java set java-21-openjdk
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

### Install jython

Download the latest stable version of Jython Standalone https://repo1.maven.org/maven2/org/python/jython-standalone/

```bash
sudo mkdir /opt/jython
sudo cp /home/justice-reaper/Downloads/jython-standalone-2.7.4.jar /opt/jython
```

### Apply Tokyo Night Dark theme

Configure your user with the GUI tools, root mirrors your user and inherits everything automatically

> **Never run `nwg-look`, `qt5ct` or `qt6ct` as root**
> Root has no D-Bus session bus, so dconf cannot save and nothing is applied

#### Rename the exported Qt color schemes

```bash
mv /home/justice-reaper/Downloads/Hyprland-Dotfiles/oomox-themes/qt5ct/colors/oomox-tokyo-night-dark-gtk4.conf /home/justice-reaper/Downloads/Hyprland-Dotfiles/oomox-themes/qt5ct/colors/oomox-tokyo-night-dark.conf
mv /home/justice-reaper/Downloads/Hyprland-Dotfiles/oomox-themes/qt6ct/colors/oomox-tokyo-night-dark-gtk4.conf /home/justice-reaper/Downloads/Hyprland-Dotfiles/oomox-themes/qt6ct/colors/oomox-tokyo-night-dark.conf
```

#### Install the theme system-wide

```bash
sudo mkdir -p /usr/share/themes/oomox-tokyo-night-dark/gtk-4.0 /usr/share/icons/oomox-tokyo-night-dark
sudo cp -r /home/justice-reaper/Downloads/Hyprland-Dotfiles/oomox-themes/gtk3/* /usr/share/themes/oomox-tokyo-night-dark
sudo cp /home/justice-reaper/Downloads/Hyprland-Dotfiles/oomox-themes/gtk4/gtk.css /usr/share/themes/oomox-tokyo-night-dark/gtk-4.0
sudo cp -r /home/justice-reaper/Downloads/Hyprland-Dotfiles/oomox-themes/icons/* /usr/share/icons/oomox-tokyo-night-dark
sudo gtk-update-icon-cache -f /usr/share/icons/oomox-tokyo-night-dark

sudo mkdir -p /usr/share/qt5ct/colors /usr/share/qt6ct/colors
sudo cp /home/justice-reaper/Downloads/Hyprland-Dotfiles/oomox-themes/qt5ct/colors/oomox-tokyo-night-dark.conf /usr/share/qt5ct/colors
sudo cp /home/justice-reaper/Downloads/Hyprland-Dotfiles/oomox-themes/qt6ct/colors/oomox-tokyo-night-dark.conf /usr/share/qt6ct/colors
```

#### Configure the theme for GTK4

GTK4 apps ignore the GSettings theme, they read this file instead

```bash
mkdir -p /home/justice-reaper/.config/gtk-4.0
ln -sf /usr/share/themes/oomox-tokyo-night-dark/gtk-4.0/gtk.css /home/justice-reaper/.config/gtk-4.0/gtk.css
```

#### Run qt5ct qt6ct and set these options

| Option | Value |
|--------|-------|
| Style | Fusion |
| Color Scheme | oomox-tokyo-night-dark |
| Standard Dialogs | gtk3 |
| Font General | Inter, 12 |
| Font Fixed Width | Inter, 12 |
| Icon Theme | oomox-tokyo-night-dark |

```bash
qt5ct
qt6ct
```

#### Run nwg-look and set these options

| Option | Value |
|--------|-------|
| Widget Theme | oomox-tokyo-night-dark |
| Icon Theme | oomox-tokyo-night-dark |
| Default Font | Inter Regular, 12 |
| Color Scheme | prefer-dark |
| Cursor Theme | Windows-10-Alt-Light |

```bash
mkdir -p /home/justice-reaper/.icons
nwg-look
```

#### Make root mirror your user

`file-db` lets root read your dconf database, the symlinks do the same for Qt and GTK4

```bash
sudo mkdir -p /etc/dconf/profile /root/.config

sudo tee /etc/dconf/profile/user > /dev/null <<'EOF'
user-db:user
file-db:/home/justice-reaper/.config/dconf/user
EOF

sudo ln -s /home/justice-reaper/.config/qt5ct /root/.config/qt5ct
sudo ln -s /home/justice-reaper/.config/qt6ct /root/.config/qt6ct
sudo ln -s /home/justice-reaper/.config/gtk-4.0 /root/.config/gtk-4.0
```

#### Verify that root inherited the theme

```bash
dconf dump /org/gnome/desktop/interface/
sudo -H gsettings get org.gnome.desktop.interface icon-theme
```

Both must show `oomox-tokyo-night-dark`

If there are any issues, you can recreate the theme by following the steps in oomox-user-preset/RECREATE-OOMOX-THEME.md

### Add custom tools

```bash
sudo cp bin/* /usr/local/bin
sudo wget https://raw.githubusercontent.com/Justice-Reaper/rpc-enum/refs/heads/main/rpc-enum -O /usr/local/bin/rpc-enum && sudo chmod +x /usr/local/bin/rpc-enum
sudo wget https://raw.githubusercontent.com/Justice-Reaper/graphql-converter/refs/heads/main/graphql-converter -O /usr/local/bin/graphql-converter && sudo chmod +x /usr/local/bin/graphql-converter
sudo wget https://raw.githubusercontent.com/Justice-Reaper/payload-splitter/refs/heads/main/payload-splitter -O /usr/local/bin/payload-splitter && sudo chmod +x /usr/local/bin/payload-splitter
sudo wget https://raw.githubusercontent.com/Justice-Reaper/get-top-ports/refs/heads/main/get-top-ports -O /usr/local/bin/get-top-ports && sudo chmod +x /usr/local/bin/get-top-ports
sudo wget https://raw.githubusercontent.com/Justice-Reaper/ip-range-generator/refs/heads/main/ip-range-generator -O /usr/local/bin/ip-range-generator && sudo chmod +x /usr/local/bin/ip-range-generator
```

### Install icons font

```bash
sudo cp -r fonts /usr/local/share
sudo fc-cache -fv
```

If there are any issues, you can recreate the icons font. This reads the SVGs in `generate-icons-font/icons`, writes the font to `fonts/Icons Font.ttf` and the codepoint map to `generate-icons-font/icon-chars.sh`. See `generate-icons-font/README.md` for how to add or change icons

```bash
cd generate-icons-font
fontforge -lang=py -script build-waybar-icons-font.py
```

### Set system default terminal

```bash
gsettings set org.cinnamon.desktop.default-applications.terminal exec kitty
```

### Configure Firefox middle-click autoscroll

Open Firefox, type about:config in the address bar and set general.autoScroll to true

### Configure sddm and quickshell

Follow these steps to install sddm as display manager and quickshell as lockscreen https://github.com/Justice-Reaper/qylock.git

### Make the SDDM login screen match your session (cursor, brightness, nightlight)

By default the SDDM login screen does not match the Hyprland session. The `sddm/sddm-xsetup` script runs as the X11 `DisplayCommand` (before the greeter paints) and mirrors the session by reading the same state files it saves in `/home/justice-reaper/.config/bin`

- **Cursor** — the Qt6 greeter otherwise falls back to the Adwaita cursor (a black X / wrong pointer) because `xcb-util-cursor` ignores `XCURSOR_THEME`; the script sets `Xcursor.theme` through `xrdb` (the only channel the Qt6 greeter reads) and also loads the root-window cursor with `xsetroot`, so the login screen uses `Windows-10-Alt-Light`
- **Brightness** — applies the value saved in `/home/justice-reaper/.config/bin/brightness` with `brightnessctl`
- **Nightlight** — if `/home/justice-reaper/.config/bin/nightlight-status` is `On`, sets the kelvin saved in `/home/justice-reaper/.config/bin/nightlight` directly with `redshift` (`redshift -P -O`, one-shot, no conversion needed); if `Off`, the screen stays neutral

`sddm/theme.conf` wires it together: it selects the theme and points the X11 `DisplayCommand` at the script

Install the dependencies

```bash
sudo pacman -S xorg-xsetroot xorg-xrdb redshift
```

Install the setup script and the SDDM drop-in config (change `Current=` to `pixel-aquarium` if you prefer that theme)

```bash
sudo cp sddm/sddm-xsetup /usr/local/bin/sddm-xsetup
sudo mkdir /etc/sddm.conf.d
sudo cp sddm/theme.conf /etc/sddm.conf.d/theme.conf
```

### Disable the Nvidia GPU (nouveau)

The kernel loads nouveau automatically when it detects an Nvidia GPU, causing random hard freezes on hybrid laptops. Blacklisting it prevents the driver from loading, so the compositor only uses the AMD iGPU

```bash
sudo cp modprobe/blacklist-nouveau.conf /etc/modprobe.d/
sudo mkinitcpio -P
```

### Copy udev rules

```bash
sudo cp rules/* /etc/udev/rules.d/
```

### Mount dirty NTFS drives in file managers

```bash
sudo cp udisks2/mount_options.conf /etc/udisks2/
```

## 3. How to recover the system when everything breaks

### Automated rollback (from a running system)

If the system boots but something is broken, run the rollback script directly

```bash
sudo rollback
```

It lists all snapshots, asks which one to restore, backs up the current `@` as `@_old_TIMESTAMP`, creates a writable snapshot as the new `@`, and offers to reboot.

To rollback to a specific snapshot without the interactive menu

```bash
sudo rollback 750
```

After rebooting and verifying everything works, clean up old backups

```bash
sudo rollback --list                              # list old @ backups
sudo rollback --cleanup @_old_2026-06-22_22:03    # delete a specific one
sudo rollback --cleanup-all                       # delete all old @ backups
```

### Automated rollback (from a GRUB snapshot)

If the system doesn't boot at all but GRUB works

1. Reboot → in GRUB select `Artix Linux snapshots` → choose a snapshot
2. It boots with overlayfs (temporary RAM layer on top of the read-only snapshot)
3. Run the rollback script from inside the snapshot

```bash
sudo rollback
```

### Manual rollback (live USB, if GRUB is also broken)

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

View the description of each snapshot, pipe it to less so you can scroll and quit with q

```bash
for dir in /mnt/@snapshots/*/; do echo "=== $(basename $dir) ==="; grep -o '<description>.*</description>' "$dir/info.xml"; done | less
```

Move the broken system and replace with the good snapshot (change NUMBER to the one you choose)

```bash
mv /mnt/@ /mnt/@_old
btrfs subvolume snapshot /mnt/@snapshots/NUMBER/snapshot /mnt/@
```

If GRUB is also broken, fix it with chroot

```bash
mkdir -p /media
mount -o rw,noatime,compress=zstd:1,subvol=@ /dev/nvme0n1p2 /media
modprobe vfat
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
sudo btrfs subvolume delete /mnt/@_old
sudo umount /mnt
```
