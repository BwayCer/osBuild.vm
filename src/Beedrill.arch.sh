#!/bin/bash
# 殼層腳本命令次序 Shell Order
# /cygdrive/c/bway/auth.cygwin/bway/crepo/osBuild.vm/src/register.shorder/Beedrill.arch.sh


##shStyle ###


set -e


##shStyle 介面函式


fnShorder_help="\
殼層腳本命令次序 Shell Order
[[USAGE]] [次序訂單 ((n1|n1a-n1b)[,(nN|nNa-nNb) ...])]
[[OPT]]
      --all    依原定次序全部執行。
  -h, --help   幫助。
"
fnShorder() {
    opt_all=0

    while [ -n "y" ]
    do
        case "$1" in
            --all )
                opt_all=1
                shift
                ;;
            -h | --help ) echo "$fnShorder_help"; exit ;;
            * ) break ;;
        esac
    done

    local menuArgu="$1"
    local menu="$menuArgu"

    if [ $opt_all -eq 1 ]; then
        menu="1-${#fnShorder_fnNameList[@]}"
    elif [ -z "$menu" ]; then
        cat -n <<< "$fnShorder_titleTxt"
        echo -n "請以編號寫下執行順序 (ex: 4-6,1-3,7) : "
        read menu
    fi

    if [ -z "$menu" ]; then
        fnThrow "$fnShorder_filename" 1 "取消執行。"
    fi
    if [[ ! ",$menu" =~ ^(,([0-9]+|[0-9]+-[0-9]+))+$ ]]; then
        fnThrow "$fnShorder_filename" \
            1 '順序語意不符合 "(n1|n1a-n1b)[,(nN|nNa-nNb) ...]"。'
    fi

    fnShorder_run `fnShorder_run_parseMenu "$menu"`
}
fnShorder_filename="fnShorder"
fnShorder_titleTxt=""
fnShorder_fnNameList=()
fnShorder_register() {
    local txt="$1"

    local fnName=`cut -d ":" -f 1  <<< "$txt"`
    local title=` cut -d ":" -f 2-  <<< "$txt"`

    [ -z "$fnShorder_titleTxt" ] || fnShorder_titleTxt+=$_br
    [ -n "$title" ] \
        && fnShorder_titleTxt+=$title \
        || fnShorder_titleTxt+="---"

    fnShorder_fnNameList+=("$fnName")
}
fnShorder_run() {
    local menuList=("$@")

    local idx catIdx
    local title fnName
    local currLoopTimes=0
    local runTotal=${#menuList[@]}

    for idx in "${menuList[@]}"
    do
        # `set -e` 會因為 `((...))` 計算語法而退出
        currLoopTimes=$((currLoopTimes + 1))
        catIdx=$((idx - 1))
        if [ $catIdx -ge 0 ] && [ $catIdx -lt ${#fnShorder_fnNameList[@]} ]; then
            title=`sed -n "${idx}p" <<< "$fnShorder_titleTxt"`
            fnName=${fnShorder_fnNameList[catIdx]}
            printf "\n(%s/%s). %s (%s)\n\n" "$currLoopTimes" "$runTotal" "$title" "$fnName"

            sleep 1 # 思考是否繼續的緩衝時間
            case "$fnName" in
                tag )
                    echo "--- 略 ---"
                    ;;
                * )
                    set -x # 打印執行命令
                    "fnOrder_$fnName"
                    set +x
                    ;;
            esac
            printf "\n\n"
        else
            printf "\n(%s/%s). ---\n\n" "$currLoopTimes" "$runTotal"
        fi
    done
}
fnShorder_run_parseMenu() {
    local menu="$1"

    local commaVal
    local startNum endNum
    local order=()

    for commaVal in `tr "," " " <<< "$menu"`
    do
        if [[ "$commaVal" =~ - ]]; then
            startNum=`cut -d "-" -f 1 <<< "$commaVal"`
            endNum=`  cut -d "-" -f 2 <<< "$commaVal"`
            order+=(`seq $startNum $endNum`)
        else
            order+=($commaVal)
        fi
    done

    echo ${order[@]}
}


##shStyle ###


[ -n "$_br" ] || _br="
"

type "fnThrow" &> /dev/null || {
    fnThrow() {
        local fileName=$1
        local code=$2
        local msg="$3"

        if [ $# -eq 2 ]; then
            msg="$code"
            code=$fileName
            fileName=$_filename
        fi

        echo -e "[$fileName]: $msg" >&2
        exit $code
    }
}


##shStyle ###


# /bin/bash


# /dev/sda -> Beedrill

# NAME      Start (sector)   End (sector)    SIZE  FSCode   FSTYPE   MOUNTPOINT
# sda                                         84G
# ├─sda1            2048         264191      128M    EF00     vfat   /mnt/mntRoot/boot
# ├┬sda2          264192      168036351       80G    8300    btrfs   /mnt
# │├─subvol=@root                                                    /mnt/mntRoot
# │├─subvol=@varLibDocker                                            /mnt/mntRoot/var/lib/docker
# │└─subvol=@home                                                    /mnt/mntRoot/home
# ├─sda3       168036352      169084927      512M    8300     ext4   /mnt/var/log
# └─swap       169084928      176160733      3.4G    8300     swap   [SWAP]


# 取代 arch-chroot 的工具
# https://wiki.archlinux.org/index.php/Systemd-nspawn


# # 同掛在磁區下有一樣的答案？
# btrfs subvolume list -p .



#
# 共享變數 & 函式庫
#

rootDevPath="/dev/sda2"
rootMountPath="/mnt/mntRoot"


fnNspawn() {
    local mothodPrifx user
    if [ "$1" == "-u" ]; then
        mothodPrifx="user"
        user=$2
        shift 2
    fi

    local method="$1"; shift

    case "${mothodPrifx}_${method}" in
        _-- ) systemd-nspawn -D "$rootMountPath" -- "$@" ;;
        _-P ) systemd-nspawn -D "$rootMountPath" -P <<< "$1" ;;
        user_-- ) systemd-nspawn -D "$rootMountPath" -u "$user" -- "$@" ;;
        user_-P ) systemd-nspawn -D "$rootMountPath" -u "$user" -P <<< "$@" ;;
    esac
}

fnNspawn_makePkg() {
    local who="$1"
    local pkgName="$2"

    fnNspawn -u "$who" -P <<< '
        local downloadDir="$HOME/Desktop/Download"
        local pkgDir="$downloadDir/'$pkgName'"

        [ -d "$downloadDir" ] || mkdir -p "$downloadDir"
        [ ! -d "$pkgDir" ] || rm -rf "$pkgDir"

        git clone "https://aur.archlinux.org/'$pkgName'.git" "$pkgDir"
        cd "$pkgDir"
        # 必須切換到一般用戶
        sudo -u "$who" makepkg -sic --noconfirm
    '
}

fnSnapshotAll() {
    local tag="$1"

    local dateTxt="`date "+%Y%m%d-%H%M"`"

    if [ "`lsblk -o MOUNTPOINT "$rootDevPath" | sed -n "2p"`" != "/mnt" ]; then
        mount "$rootDevPath" /mnt
    fi
    [ -d "/mnt/snapshot" ] || mkdir -p /mnt/snapshot

    btrfs subvolume snapshot /mnt/volume/@root         "/mnt/snapshot/@root-$dateTxt-$tag"
    btrfs subvolume snapshot /mnt/volume/@home         "/mnt/snapshot/@home-$dateTxt-$tag"
    btrfs subvolume snapshot /mnt/volume/@varLibDocker "/mnt/snapshot/@varLibDocker-$dateTxt-$tag"

    echo
    btrfs subvolume list /mnt
    echo
    du -hs /mnt/volume/*  /mnt/snapshot/*
}



#
# 安裝工具環境
#
fnShorder_register "tag:ISO>> 安裝工具環境"


fnShorder_register "setInstallerEnv:設定安裝工具環境"
fnOrder_setInstallerEnv() {
    pacman -Sy
    pacman -S --noconfirm btrfs-progs
}


#
# 磁碟分割
#
fnShorder_register "tag:ISO>> 磁碟分割"


fnShorder_register "diskPartition:磁碟分區 root-btrfs-84G"
fnOrder_diskPartition() {
    sgdisk --zap-all --clear --mbrtogpt /dev/sda
    sgdisk -n       1:2048:264191     -t 1:EF00    /dev/sda
    sgdisk -n     2:264192:168036351  -t 2:8300    /dev/sda
    sgdisk -n  3:168036352:169084927  -t 3:8300    /dev/sda
    sgdisk -n  4:169084928:176160733  -t 4:8300 -p /dev/sda
}

fnShorder_register "diskFormat:格式化 root-btrfs-84G"
fnOrder_diskFormat() {
    mkfs.vfat /dev/sda1
    mkfs.btrfs -f -L ArchRoot "$rootDevPath"
    mkfs.ext4 -L varLog /dev/sda3

    mkswap /dev/sda4

    echo
    lsblk -o NAME,SIZE,RA,RO,RM,RAND,PARTFLAGS,PARTLABEL,PARTUUID
    echo
    lsblk -o NAME,FSTYPE,LABEL,UUID
    echo
    free
}

fnShorder_register "mountDrive:掛載硬碟 root-btrfs-84G"
fnOrder_mountDrive() {
    mount -o compress=zstd "$rootDevPath" /mnt

    mkdir -p /mnt/volume
    btrfs subvolume create /mnt/volume/@root
    btrfs subvolume create /mnt/volume/@home
    btrfs subvolume create /mnt/volume/@varLibDocker

    # `subvol` 的屬性值為相對於其磁區位置的子數據卷路徑
    mkdir -p "$rootMountPath"
    mount -o compress=zstd,subvol=./volume/@root "$rootDevPath" "$rootMountPath"

    mkdir -p "$rootMountPath/var/lib/docker"
    mount -o compress=zstd,subvol=./volume/@varLibDocker "$rootDevPath" "$rootMountPath/var/lib/docker"

    mkdir -p "$rootMountPath/home"
    mount -o compress=zstd,subvol=./volume/@home "$rootDevPath" "$rootMountPath/home"

    mkdir -p "$rootMountPath/boot"
    mount /dev/sda1 "$rootMountPath/boot"

    mkdir -p "$rootMountPath/var/log"
    mount /dev/sda3 "$rootMountPath/var/log"

    swapon /dev/sda4

    echo
    lsblk -o NAME,MOUNTPOINT,FSTYPE,LABEL,UUID
    echo
    df -Th | sed -n '1p'
    df -Th | grep "$rootMountPath"
}



#
# 作業系統
#
fnShorder_register "tag:ISO>> 作業系統"


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
    pacstrap "$rootMountPath" base linux btrfs-progs dhcpcd vim
        # btrfs-progs
        #   https://wiki.archlinux.org/index.php/Mkinitcpio#HOOKS
        #   若沒安裝，建立開機映像 `mkinitcpio -p linux` 命令會拋出以下錯誤導致無法開機
        #     ==> ERROR: file not found: `fsck.btrfs'

    ln -sf /usr/bin/vim "$rootMountPath/usr/bin/vi"
}

fnShorder_register "writeFstab:掛載寫入文件系統列表"
fnOrder_writeFstab() {
    genfstab -U "$rootMountPath" > "$rootMountPath/etc/fstab"
    cat "$rootMountPath/etc/fstab"
}

fnShorder_register "buildBootUpProgram:arch-chroot 建立開機程式"
fnOrder_buildBootUpProgram () {
    # 建立開機映像
    systemd-nspawn -D "$rootMountPath" -- mkinitcpio -p linux

    # 建立開機程式
    systemd-nspawn -D "$rootMountPath" -- bootctl install

    # 建立開機選單：
    echo -e "default arch\ntimeout 3" > "$rootMountPath/boot/loader/loader.conf"
    local rootPartuuid=`
        blkid -s PARTUUID "$rootDevPath" |
            sed "s/.*PARTUUID=\"\([a-f0-9-]\+\)\"/\1/"
    `
    printf "%s\n" \
        "title Archlinux" \
        "linux /vmlinuz-linux" \
        "initrd /initramfs-linux.img" \
        "options root=PARTUUID=$rootPartuuid rw rootflags=subvol=volume/@root" \
        > "$rootMountPath/boot/loader/entries/arch.conf"
}

fnShorder_register "buildSsh:arch-chroot 建立網路與 SSH 通信"
fnOrder_buildSsh () {
    systemd-nspawn -D "$rootMountPath" -- pacman -S --noconfirm openssh

    local sshConfInsertNumber=`
        grep -nm 1 "^#PasswordAuthentication" "$rootMountPath/etc/ssh/sshd_config" |
            sed "s/^ *\([0-9]\+\):.*$/\1/"
    `
    [ -n "$sshConfInsertNumber" ] \
        && sed -i "${sshConfInsertNumber}a PasswordAuthentication no" "$rootMountPath/etc/ssh/sshd_config" \
        || echo "PasswordAuthentication no" >> "$rootMountPath/etc/ssh/sshd_config"

    systemd-nspawn -D "$rootMountPath" -P <<< 'sh <(curl https://raw.githubusercontent.com/BwayCer/osBuild.vm/master/lib/createVmPass-universal) -H "$HOME"'
    systemd-nspawn -D "$rootMountPath" -- systemctl enable dhcpcd.service
    systemd-nspawn -D "$rootMountPath" -- systemctl enable sshd.service
}

fnShorder_register "hostSign:arch-chroot 主機簽名"
fnOrder_hostSign () {
    echo Beedrill > "$rootMountPath/etc/hostname"
}

fnShorder_register "snapshotOrigin:Btrfs Snapshot Origin"
fnOrder_snapshotOrigin() {
    fnSnapshotAll origin
}



#
# 環境配置
#
fnShorder_register "tag:UserRoot>> 環境配置"


fnShorder_register "setTime:設定時間"
fnOrder_setTime () {
    fnNspawn -- ln -sf /usr/share/zoneinfo/Asia/Taipei /etc/localtime
    fnNspawn -- pacman -S --noconfirm ntp
    fnNspawn -- ntpdate time.stdtime.gov.tw
    # 查看時間
    # Error: System has not been booted with systemd as init system (PID 1). Can't operate.
    # fnNspawn -- timedatectl
}

fnShorder_register "setLanguage:設定語系"
fnOrder_setLanguage () {
    fnNspawn -- sed -i "s/^#\(\(en_US\|zh_TW\).UTF-8 UTF-8\)/\1/" /etc/locale.gen
    fnNspawn -- locale-gen
    fnNspawn -P '
        locale |
            sed "s/\([A-Z_]=\).*/\1\"zh_TW.UTF-8\"/" |
            sed "s/\(LC_\(TIME\)=\).*/\1\"en_US.UTF-8\"/" \
            > /etc/locale.conf
    '
}

fnShorder_register "iLikePackage:主要程式包安裝"
fnOrder_iLikePackage() {
    fnNspawn -- pacman -S --noconfirm archlinux-keyring \
        # archlinux-keyring
        #   用 pacstrap 安裝竟然沒用?!
        #   若沒安裝，在安裝 docker 時會出現
        #   invalid or corrupted package (PGP signature)
    fnNspawn -- pacman -S --noconfirm \
        bash-completion tmux wget tree rsync \
        nmap base-devel \
        git docker
    # fnNspawn -- pacman -S --noconfirm \
    #     arch-install-scripts gptfdisk exfat-utils partclone \
    #     cifs-utils ntfs-3g

    fnNspawn -- systemctl enable docker.service
}



#
# 普通用戶
#
fnShorder_register "tag:UserRoot>> 普通用戶"


fnShorder_register "userMustTool:用戶必須工具"
fnOrder_userMustTool() {
    fnNspawn -- pacman -S --noconfirm sudo

    # visudo
    local configFilePath="$rootMountPath/etc/sudoers"
    local txt="%wheel ALL=(ALL) NOPASSWD: ALL"
    local sudoConfInsertNumber=`
        grep -nm 1 "^# $txt" "$configFilePath" |
            sed "s/^ *\([0-9]\+\):.*$/\1/"
    `
    [ -n "$sudoConfInsertNumber" ] \
        && sed -i "${sudoConfInsertNumber}a $txt" "$configFilePath" \
        || echo "$txt" >> "$configFilePath"
}

fnShorder_register "createUserBwaycer:新增用戶 uid-1000-bwaycer"
fnOrder_createUserBwaycer() {
    fnNspawn -- useradd -m -u 1000 -G wheel,docker bwaycer
    fnNspawn -- grep bwaycer /etc/passwd /etc/shadow /etc/group
    fnNspawn -- passwd -d bwaycer
}

fnShorder_register "snapshotOrigEnvBwaycer:Btrfs Snapshot OrigEnvBwaycer"
fnOrder_snapshotOrigEnvBwaycer() {
    fnSnapshotAll OrigEnvBwaycer
}



#
# 桌面環境
#
fnShorder_register "tag:UserBway>> 桌面環境"

# ~/.icons =~ /usr/share/icons
# /etc/skel   <-- 家目錄的參考目錄
# ~/.xprofile <-- 圖形介面的 .profile


fnShorder_register "xfce:Xfce 桌面環境"
fnOrder_xfce() {
    # 有次序問題
    # adobe-source-han-serif-otc-fonts 思源宋體 (解決 檔、啟 等中文字有缺字問題)
    fnNspawn -u "bwaycer" -- sudo pacman -S --noconfirm \
        xorg lightdm-gtk-greeter adobe-source-han-serif-otc-fonts
    # alsa-utils 聲音工具
    fnNspawn -u "bwaycer" -- sudo pacman -S --noconfirm \
        xfce4 xfce4-taskmanager xdg-utils alsa-utils \
        arc-gtk-theme

    # 圖示
    fnNspawn -u "bwaycer" -P 'git clone https://github.com/rudrab/Shadow.git "$HOME/.icons/Shadow"'

    # lightdm-gtk-greeter 登錄管理器
    fnNspawn -u "bwaycer" -- sudo systemctl enable lightdm.service
}

fnShorder_register "installHime:輸入法"
fnOrder_installHime() {
    fnNspawn_makePkg "bwaycer" "hime-git"

    # 需重新登入
    fnNspawn -u "bwaycer" -P '
        printf "%s\n" "" \
            "export LANG=\"zh_TW.UTF-8\"" \
            "export XMODIFIERS=\"@im=hime\"" \
            "export XMODIFIER=\"@im=hime\"" \
            "export GTK_IM_MODULE=hime" \
            "export QT_IM_MODULE=hime" \
            "export DefaultIMModule=hime" \
            "export XMODIFIERS=@im=hime" \
            "export LC_CTYPE=zh_TW.UTF-8" \
            "hime &" \
            "" >> "$HOME/.xprofile"
    '
}

fnShorder_register "installChrome:安裝 Google Chrome"
fnOrder_installChrome() {
    # ex: google-chrome-73.0.3683.75-1-x86_64.pkg.tar.xz
    fnNspawn_makePkg "bwaycer" "google-chrome"
}

fnShorder_register "installVirtualboxTool:安裝 Virtualbox 工具"
fnOrder_installVirtualboxTool() {
    # 調整客體大小的圖形控制器要設定為 VBoxVGA or VBoxSVGA
    fnNspawn -u "bwaycer" -- sudo pacman -S virtualbox-guest-utils
    fnNspawn -u "bwaycer" -- sudo systemctl enable vboxservice.service
}

fnShorder_register "snapshotOrigEnvDesktop:Btrfs Snapshot OrigEnvDesktop"
fnOrder_snapshotOrigEnvDesktop() {
    fnSnapshotAll OrigEnvDesktop
}



#
# 結束
#

fnShorder_register "poweroff:卸載及關機"
fnOrder_poweroff () {
    umount -R "$rootMountPath"
    systemctl poweroff
}




##shStyle ###


fnShorder "$@"
