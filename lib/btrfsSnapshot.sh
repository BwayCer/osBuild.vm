# /bin/bash
# YsBtrfs


##shStyle 介面函式


fnMain_help="\
YsBtrfs
[[USAGE]]
[[SUBCMD]]
  list     [[BRIEFLY:list]]
  butter   [[BRIEFLY:butter]]
[[OPT]]
  -h, --help   幫助。
"
fnMain() {
    while [ -n "y" ]
    do
        case "$1" in
            -h | --help ) echo "$fnMain_help"; exit ;;
            * ) break ;;
        esac
    done

    case "$1" in
        list | butter )
            "fnMain_$method"
            ;;
        * ) echo "$fnMain_help"; exit ;;
    esac
}

fnMain_list_help="\
列出資訊。
[[USAGE]] <Btrfs 掛載目錄>
[[OPT]]
  -h, --help   幫助。
"
fnMain_list() {
    opt_all=0

    while [ -n "y" ]
    do
        case "$1" in
            -* | -h | --help ) echo "$fnMain_list_help"; exit ;;
            * ) break ;;
        esac
    done

    btrfs subvolume list /mnt/btrfs
}


fnMain_butter_help="\
抹牛油。
# 關於 \"[快照數據卷目標路徑/快照後綴名稱]\" 參數以該路徑是否存在作為其判別方式。
[[USAGE]] <數據卷來源路徑> [快照數據卷目標路徑/快照後綴名稱]
[[OPT]]
  -h, --help   幫助。
"
fnMain_butter() {
    opt_all=0

    while [ -n "y" ]
    do
        case "$1" in
            --all )
                opt_all=1
                shift
                ;;
            -* | -h | --help ) echo "$fnMain_list_help"; exit ;;
            * ) break ;;
        esac
    done

    sudo btrfs subvolume list /mnt/btrfs
}

fnBtrfsSnapshot_filename="fnBtrfsSnapshot"
fnBtrfsSnapshot_titleTxt=""
fnBtrfsSnapshot_fnNameList=()
fnBtrfsSnapshot_register() {
    local txt="$1"

    local fnName=`cut -d ":" -f 1  <<< "$txt"`
    local title=` cut -d ":" -f 2-  <<< "$txt"`

    [ -z "$fnBtrfsSnapshot_titleTxt" ] || fnBtrfsSnapshot_titleTxt+=$_br
    [ -n "$title" ] \
        && fnBtrfsSnapshot_titleTxt+=$title \
        || fnBtrfsSnapshot_titleTxt+="---"

    fnBtrfsSnapshot_fnNameList+=("$fnName")
}
fnBtrfsSnapshot_run() {
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
        if [ $catIdx -ge 0 ] && [ $catIdx -lt ${#fnBtrfsSnapshot_fnNameList[@]} ]; then
            title=`sed -n "${idx}p" <<< "$fnBtrfsSnapshot_titleTxt"`
            fnName=${fnBtrfsSnapshot_fnNameList[catIdx]}
            printf "\n(%s/%s). %s (%s)\n\n" "$currLoopTimes" "$runTotal" "$title" "$fnName"
            "fnOrder_$fnName"
            printf "\n\n"
        else
            printf "\n(%s/%s). ---\n\n" "$currLoopTimes" "$runTotal"
        fi
    done
}
fnBtrfsSnapshot_run_parseMenu() {
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


fnMain "$@"

exit

function bsn(){
    if [ ! -z "$1" ]; then
        sudo btrfs subvolume snapshot /mnt/btrfs/@home /mnt/btrfs/@home-`date "+%Y-%m%d-%H%M"`-$1
        sudo btrfs subvolume snapshot /mnt/btrfs/@root /mnt/btrfs/@root-`date "+%Y-%m%d-%H%M"`-$1
    else
        echo "Please input name, eg: bsn init-snapshot"
    fi
    sudo btrfs subvolume list /mnt/btrfs
}

function bsnb(){
    echo "Btrfs balance 1/3"
    sudo btrfs balance start -m /mnt/btrfs
    sudo btrfs fi show
    echo "Btrfs balance 1/3 finished!!"
    sudo btrfs fi df /mnt/btrfs
    echo "Btrfs balance 2/3"
    sudo btrfs fi balance start -dusage=10 /mnt/btrfs
    sudo btrfs fi show
    echo "Btrfs balance 2/3 finished!!"
    echo "Btrfs balance 3/3"
    sudo btrfs fi balance start /mnt/btrfs
    sudo btrfs fi show
    echo "Btrfs balance 3/3 finished!!"
}

function bsnd(){
    if [ ! -z "$1" ]; then
        sudo btrfs subvolume delete /mnt/btrfs/@home-$1
        sudo btrfs subvolume delete /mnt/btrfs/@root-$1
    else
        echo "Please input name for delete, eg: bsnd init-snapshot"
    fi
    sudo btrfs subvolume list /mnt/btrfs
}

function bsnr(){
    if [ ! -z "$1" ]; then
        sudo mv /mnt/btrfs/@home /mnt/btrfs/@home-bad-`date "+%Y-%m%d-%H%M"`
        sudo mv /mnt/btrfs/@root /mnt/btrfs/@root-bad-`date "+%Y-%m%d-%H%M"`
        sudo mv /mnt/btrfs/@home-$1 /mnt/btrfs/@home
        sudo mv /mnt/btrfs/@root-$1 /mnt/btrfs/@root
    else
        echo "Please input name for delete, eg: bsnd init-snapshot"
    fi
    sudo ls -al /mnt/btrfs
    sudo btrfs subvolume list /mnt/btrfs
}

