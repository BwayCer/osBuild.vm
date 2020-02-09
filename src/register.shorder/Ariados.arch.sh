# /bin/bash

# /dev/sda -> Altaria
# /dev/sdb -> Swablu

# NAME      Start (sector)   End (sector)    SIZE  FSCode   FSTYPE   MOUNTPOINT
# sda                                         32G
# ├─sda1            2048       65013759       31G    8300     ext4   /mnt
# ├─sda2        65013760       65275903      128M    EF00     ext4   /mnt/boot
# └─sda3        65275904       66324479      512M    8300     ext4   /mnt/var/log

# sdb                                         82G
# ├─sdb1            2048       96471039       46G    8300     ext4   /mnt/home
# ├─sdb2        96471040      155191295       28G    8300     ext4   /mnt/var/lib/docker
# └─sdb3       155191296      167774207        6G    8300     ext4   /mnt/var/cache/pacman/pkg



#
# 共享變數 & 函式庫
#

fnMakePkg() {
    local who="$1"
    local homePath="$2"
    local pkgName="$3"

    local currPath="$PWD"
    local downloadDir="$homePath/Desktop/Download"
    local pkgDir="$downloadDir/$pkgName"

    [ -d "$downloadDir" ] || mkdir -p "$downloadDir"
    [ ! -d "$pkgDir" ] || rm -rf "$pkgDir"

    git clone "https://aur.archlinux.org/${pkgName}.git" "$pkgDir"
    cd "$pkgDir"
    # 必須切換到一般用戶
    sudo -u "$who" makepkg -sic --noconfirm
    # or
    #   makepkg -s
    #   sudo pacman -U ${pkgName}-*-x86_64.pkg.tar.xz
    cd "$currPath"
}



#
# 磁碟分割
#
fnShorder_register "tag:>> 磁碟分割"


fnShorder_register "diskPartition:磁碟分區 root-32G"
fnOrder_diskPartition() {
    sgdisk --zap-all --clear --mbrtogpt /dev/sda
    sgdisk -n      1:2048:65013759  -t 1:8300    /dev/sda
    sgdisk -n  2:65013760:65275903  -t 2:EF00    /dev/sda
    sgdisk -n  3:65275904:66324479  -t 3:8300 -p /dev/sda
}

fnShorder_register "diskFormat:格式化 root-32G"
fnOrder_diskFormat() {
    mkfs.ext4 -L Root /dev/sda1
    mkfs.vfat /dev/sda2
    mkfs.ext4 -L varLog /dev/sda3

    lsblk -o NAME,SIZE,RA,RO,RM,RAND,PARTFLAGS,PARTLABEL,PARTUUID
    lsblk -o NAME,FSTYPE,LABEL,UUID
}

fnShorder_register "mountDrive:掛載硬碟 root-32G"
fnOrder_mountDrive() {
    mount /dev/sda1 /mnt

    mkdir /mnt/boot
    mount /dev/sda2 /mnt/boot

    mkdir -p /mnt/var/log
    mount /dev/sda3 /mnt/var/log

    lsblk -o NAME,MOUNTPOINT,FSTYPE,LABEL,UUID
}

fnShorder_register "diskPartitionHome:磁碟分區 Home-82G"
fnOrder_diskPartitionHome() {
    sgdisk --zap-all --clear --mbrtogpt /dev/sdb
    sgdisk -n       1:2048:96471039   -t 1:8300    /dev/sdb
    sgdisk -n   2:96471040:155191295  -t 2:8300    /dev/sdb
    sgdisk -n  3:155191296:167774207  -t 3:8300 -p /dev/sdb
}

fnShorder_register "diskFormatHome:格式化 Home-82G"
fnOrder_diskFormatHome() {
    mkfs.ext4 -L Home /dev/sdb1
    mkfs.ext4 -L ArchDocker /dev/sdb2
    mkfs.ext4 -L ArchPkg /dev/sdb3

    lsblk -o NAME,SIZE,RA,RO,RM,RAND,PARTFLAGS,PARTLABEL,PARTUUID
    lsblk -o NAME,FSTYPE,LABEL,UUID
}

fnShorder_register "mountDriveHome:掛載硬碟 Home-82G"
fnOrder_mountDriveHome() {
    mkdir -p /mnt/home
    mount /dev/sdb1 /mnt/home

    mkdir -p /mnt/var/lib/docker
    mount /dev/sdb2 /mnt/var/lib/docker

    mkdir -p /mnt/var/cache/pacman/pkg
    mount /dev/sdb3 /mnt/var/cache/pacman/pkg

    lsblk -o NAME,MOUNTPOINT,FSTYPE,LABEL,UUID
}



#
# 作業系統
#
fnShorder_register "tag:>> 作業系統"


fnShorder_register "chooseMirrorlist:選擇映射站"
fnOrder_chooseMirrorlist() {
    # 使用 > 會產生空白文件 所以改用 tee
    cat /etc/pacman.d/mirrorlist |
        grep "http://[^/]\+\.tw/.\+" |
        tee /etc/pacman.d/mirrorlist

    cat /etc/pacman.d/mirrorlist
}

fnShorder_register "installBasePackage:安裝基本程式包"
fnOrder_installBasePackage() {
    # https://wiki.archlinux.org/index.php/Installation_guide#Install_essential_packages
    pacstrap /mnt base linux linux-firmware dhcpcd vim
        # linux-firmware 硬體支援?

    ln -s /usr/bin/vim /mnt/usr/bin/vi
}

fnShorder_register "writeFstab:掛載寫入文件系統列表"
fnOrder_writeFstab() {
    genfstab -U /mnt >> /mnt/etc/fstab
    cat /mnt/etc/fstab
}

fnShorder_register "buildBootUpProgram:arch-root 建立開機程式"
fnOrder_buildBootUpProgram () {
    # 建立開機映像
    arch-chroot /mnt <<< 'mkinitcpio -p linux'

    # 建立開機程式
    arch-chroot /mnt <<< 'bootctl install'

    # 建立開機選單：
    echo -e "default arch\ntimeout 3" > /mnt/boot/loader/loader.conf
    local rootPartuuid=`
        blkid -s PARTUUID /dev/sda1 |
            sed "s/.*PARTUUID=\"\([a-f0-9-]\+\)\"/\1/"
    `
    printf "%s\n" \
        "title Archlinux" \
        "linux /vmlinuz-linux" \
        "initrd /initramfs-linux.img" \
        "options root=PARTUUID=$rootPartuuid rw" \
        > /mnt/boot/loader/entries/arch.conf
}

fnShorder_register "buildSsh:arch-root 建立網路與 SSH 通信"
fnOrder_buildSsh () {
    arch-chroot /mnt <<< 'pacman -S --noconfirm openssh'

    local sshConfInsertNumber=`
        grep -nm 1 "^#PasswordAuthentication" /mnt/etc/ssh/sshd_config |
            sed "s/^ *\([0-9]\+\):.*$/\1/"
    `
    [ -n "$sshConfInsertNumber" ] \
        && sed -i "${sshConfInsertNumber}a PasswordAuthentication no" /mnt/etc/ssh/sshd_config \
        || echo "PasswordAuthentication no" >> /mnt/etc/ssh/sshd_config

    arch-chroot /mnt <<< 'sh <(curl https://raw.githubusercontent.com/BwayCer/osBuild.vm/master/lib/createVmPass-universal) -H "$HOME"'
    arch-chroot /mnt <<< 'systemctl enable dhcpcd.service'
    arch-chroot /mnt <<< 'systemctl enable sshd.service'
}

fnShorder_register "hostSign:arch-root 主機簽名"
fnOrder_hostSign () {
    arch-chroot /mnt <<< 'echo Ariados > /etc/hostname'
}

fnShorder_register "poweroff:卸載及關機"
fnOrder_poweroff () {
    umount -R /mnt
    systemctl poweroff
}



#
# 環境配置
#
fnShorder_register "tag:>> 環境配置"


fnShorder_register "setTime:設定時間"
fnOrder_setTime () {
    ln -sf /usr/share/zoneinfo/Asia/Taipei /etc/localtime
    pacman -S --noconfirm ntp
    ntpdate time.stdtime.gov.tw
    # 查看時間
    timedatectl
}

fnShorder_register "setLanguage:設定語系"
fnOrder_setLanguage () {
    sed -i "s/^#\(\(en_US\|zh_TW\).UTF-8 UTF-8\)/\1/" /etc/locale.gen
    locale-gen
    locale |
        sed "s/\([A-Z_]=\).*/\1\"zh_TW.UTF-8\"/" |
        sed "s/\(LC_\(TIME\)=\).*/\1\"en_US.UTF-8\"/" \
        > /etc/locale.conf
}

fnShorder_register "iLikePackage:主要程式包安裝"
fnOrder_iLikePackage() {
    pacman -S --noconfirm \
        bash-completion base-devel tmux wget tree \
        nmap \
        git docker
    # pacman -S --noconfirm \
    #     arch-install-scripts gptfdisk exfat-utils partclone \
    #     cifs-utils ntfs-3g

    systemctl enable docker.service
}



#
# 普通用戶
#
fnShorder_register "tag:>> 普通用戶"


fnShorder_register "userMustTool:用戶必須工具"
fnOrder_userMustTool() {
    pacman -S --noconfirm sudo

    # visudo
    local txt="%wheel ALL=(ALL) NOPASSWD: ALL"
    local sudoConfInsertNumber=`
        grep -nm 1 "^# $txt" /etc/sudoers |
            sed "s/^ *\([0-9]\+\):.*$/\1/"
    `
    [ -n "$sudoConfInsertNumber" ] \
        && sed -i "${sudoConfInsertNumber}a $txt" /etc/sudoers \
        || echo "$txt" >> /etc/sudoers
}

fnShorder_register "createUserBwaycer:新增用戶 uid-1000-bwaycer"
fnOrder_createUserBwaycer() {
    useradd -m -u 1000 -G wheel,docker bwaycer
    grep bwaycer /etc/passwd /etc/shadow /etc/group
    passwd -d bwaycer
}

# fnShorder_register "addUserBwaycer:加入用戶 uid-1000-bwaycer"
# fnOrder_addUserBwaycer() {
#     useradd -M -u 1000 -G wheel,docker bwaycer
#     grep bwaycer /etc/passwd /etc/shadow /etc/group
#     passwd -d bwaycer
# }



#
# 桌面環境
#
fnShorder_register "tag:>> 桌面環境"

# ~/.icons =~ /usr/share/icons
# /etc/skel   <-- 家目錄的參考目錄
# ~/.xprofile <-- 圖形介面的 .profile


fnShorder_register "xfce:Xfce 桌面環境"
fnOrder_xfce() {
    # 有次序問題
    # adobe-source-han-serif-otc-fonts 思源宋體 (解決 檔、啟 等中文字有缺字問題)
    sudo pacman -S --noconfirm \
        xorg lightdm-gtk-greeter adobe-source-han-serif-otc-fonts
    # alsa-utils 聲音工具
    sudo pacman -S --noconfirm \
        xfce4 xfce4-taskmanager xdg-utils alsa-utils \
        arc-gtk-theme

    # 圖示
    git clone https://github.com/rudrab/Shadow.git "$HOME/.icons/Shadow"

    # lightdm-gtk-greeter 登錄管理器
    sudo systemctl enable lightdm.service
}

fnShorder_register "installHime:輸入法"
fnOrder_installHime() {
    fnMakePkg "bwaycer" "$HOME" "hime-git"

    # 需重新登入
    printf "%s\n" "" \
        'export LANG="zh_TW.UTF-8"' \
        'export XMODIFIERS="@im=hime"' \
        'export XMODIFIER="@im=hime"' \
        'export GTK_IM_MODULE=hime' \
        'export QT_IM_MODULE=hime' \
        'export DefaultIMModule=hime' \
        'export XMODIFIERS=@im=hime' \
        'export LC_CTYPE=zh_TW.UTF-8' \
        'hime &' \
        "" >> "$HOME/.xprofile"
}

fnShorder_register "installChrome:安裝 Google Chrome"
fnOrder_installChrome() {
    # ex: google-chrome-73.0.3683.75-1-x86_64.pkg.tar.xz
    fnMakePkg "bwaycer" "$HOME" "google-chrome"
}

fnShorder_register "installVirtualboxTool:安裝 Virtualbox 工具"
fnOrder_installVirtualboxTool() {
    # 調整客體大小的圖形控制器要設定為 VBoxVGA or VBoxSVGA
    sudo pacman -S virtualbox-guest-utils
    sudo systemctl enable vboxservice.service
}

