#!/bin/bash
###
# FilePath    : build-openwrt/build-openwrt.sh
# Author      : jiaopengzi
# Blog        : https://jiaopengzi.com
# Description : 编译并打包 OpenWrt 固件.
#
# @example1     : bash build-openwrt.sh 手动输入密码
# @example2     : bash build-openwrt.sh password 自动输入密码
#
# 感谢如下大佬的奉献
# coolsnowwolf      https://github.com/coolsnowwolf/lede
# esirplayground    https://github.com/esirplayground/AutoBuild-OpenWrt
# fw876             https://github.com/fw876/helloworld
#
# 还有很多其他大佬，感谢你们的付出。
###

set -e

# 设置密码
PASSWORD=$1

# 初始版本
KERNEL_VERSION_DEFAULT="6.18"
CONFIG_FILE="x86_64_nft.config"

# 输出带时间、级别和阶段的日志; 参数依次为级别、阶段和内容.
# 级别不区分大小写; 终端按级别着色, 非终端或禁色时输出纯文本; 失败时返回非零.
log() {
    local level color reset
    level=${1^^}
    case "$level" in
        DEBUG) color=$'\033[36m' ;;
        INFO)  color=$'\033[32m' ;;
        WARN)  color=$'\033[33m' ;;
        ERROR) color=$'\033[31m' ;;
        *) printf '未知日志级别: %s\n' "$1" >&2; return 2 ;;
    esac
    reset=$'\033[0m'
    if [[ ( ! -t 1 && ! -t 3 ) || ${TERM:-dumb} == dumb || -n ${NO_COLOR:-} ]]; then
        color=''
        reset=''
    fi
    printf '[%(%Y-%m-%d %H:%M:%S)T] %s[%s]%s [%s] %s\n' -1 "$color" "$level" "$reset" "$2" "$3"
}

# 结束日志转发并等待写入完成; 保留原退出码, 日志写入失败时返回非零.
finish_logging() {
    local result=$? tee_result=0 error_tee_result=0 filter_result=0 cleanup_result=0
    trap - EXIT
    exec 1>&3 2>&4
    wait "$LOG_TEE_PID" || tee_result=$?
    wait "$LOG_ERROR_TEE_PID" || error_tee_result=$?
    wait "$LOG_FILTER_PID" || filter_result=$?
    rm -f -- "$LOG_FIFO" "$LOG_INPUT_FIFO" "$LOG_ERROR_FIFO" || cleanup_result=$?
    rmdir -- "$LOG_TEMP_DIR" || cleanup_result=$?
    if ((tee_result != 0 || error_tee_result != 0 || filter_result != 0 || cleanup_result != 0)); then
        printf '日志写入或临时文件清理失败: %s\n' "$LOG_FILE" >&2
        if ((result == 0)); then result=1; fi
    fi
    exit "$result"
}

# 创建独立日志并同时转发终端输出; 无参数, 初始化失败时返回非零.
start_logging() {
    local timestamp
    mkdir -p logs || return 1
    printf -v timestamp '%(%Y%m%d-%H%M%S)T' -1
    LOG_FILE=$(mktemp "logs/build-${timestamp}-XXXXXX.log") || return 1
    LOG_TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/openwrt-log-XXXXXX") || return 1
    LOG_FIFO="$LOG_TEMP_DIR/output"
    LOG_INPUT_FIFO="$LOG_TEMP_DIR/input"
    LOG_ERROR_FIFO="$LOG_TEMP_DIR/error"
    if ! mkfifo "$LOG_FIFO" "$LOG_INPUT_FIFO" "$LOG_ERROR_FIFO"; then
        rm -f -- "$LOG_FIFO" "$LOG_INPUT_FIFO" "$LOG_ERROR_FIFO"
        rmdir -- "$LOG_TEMP_DIR"
        return 1
    fi

    # 脱色后写入文件, 同时将原始输出转发至原终端; 中断时先完成日志写入.
    exec 3>&1 4>&2
    (trap '' INT QUIT; exec sed -u $'s/\033\\[[0-9;]*m//g') < "$LOG_FIFO" >> "$LOG_FILE" &
    LOG_FILTER_PID=$!
    (trap '' INT QUIT; exec tee "$LOG_FIFO") < "$LOG_INPUT_FIFO" >&3 &
    LOG_TEE_PID=$!
    (trap '' INT QUIT; exec tee "$LOG_FIFO") < "$LOG_ERROR_FIFO" >&4 &
    LOG_ERROR_TEE_PID=$!
    trap finish_logging EXIT
    exec 1> "$LOG_INPUT_FIFO" 2> "$LOG_ERROR_FIFO"
    log INFO 日志 "本次日志: $LOG_FILE"
}

# 计时函数
timer() {
    local start_time event end_time time_elapsed hours minutes seconds
    start_time=$1 # 添加一个新的参数来传递开始时间
    event=$2      # 添加一个新的参数来传递自定义的文本
    end_time=$(date +%s)
    time_elapsed=$((end_time - start_time))
    hours=$((time_elapsed / 3600))
    minutes=$(((time_elapsed / 60) % 60))
    seconds=$((time_elapsed % 60))
    log INFO 计时 "${event}共计用时: ${hours}时${minutes}分${seconds}秒"
}

# 编译函数
make_download() {
    local start_time
    KERNEL_VERSION=$1
    # 记录开始时间
    start_time=$(date +%s)

    # 打印当前目录
    log INFO 下载 "内核 $KERNEL_VERSION: 当前下载目录"
    cd openwrt || exit
    pwd

    # 指定内核版本
    sed -i "s/^KERNEL_PATCHVER:=.*$/KERNEL_PATCHVER:=$KERNEL_VERSION/" target/linux/x86/Makefile
    sed -i "s/^KERNEL_TESTING_PATCHVER:=.*$/KERNEL_TESTING_PATCHVER:=$KERNEL_VERSION/" target/linux/x86/Makefile

    log INFO 下载 "内核 $KERNEL_VERSION: 修改指定内核完成."

    log INFO 下载 "内核 $KERNEL_VERSION: 使用配置 $CONFIG_FILE"
    cp "../$CONFIG_FILE" .config || exit 1

    # defconfig
    log INFO 下载 "内核 $KERNEL_VERSION: 开始 make defconfig"
    make defconfig

    # 查看编译线程最大值
    log INFO 下载 "内核 $KERNEL_VERSION: 下载线程数量 $(nproc)"

    # 下载dl库
    log INFO 下载 "内核 $KERNEL_VERSION: 开始下载 dl 库"
    make download -j"$(nproc)"

    # 返回上层目录
    cd ..
    # 计算所用时间并输出
    timer "$start_time" "版本:$KERNEL_VERSION 下载dl库"
}

# 更新编译环境依赖及源码
update_env_source() {
    local start_time
    start_time=$(date +%s)
    packages=(
        ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential
        bzip2 ccache clang cmake cpio curl device-tree-compiler flex gawk gcc-multilib g++-multilib gettext
        genisoimage git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libfuse-dev libglib2.0-dev
        libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev libpython3-dev
        libreadline-dev libssl-dev libtool llvm lrzsz msmtp ninja-build p7zip p7zip-full patch pkgconf
        python3 python3-pyelftools python3-setuptools qemu-utils rsync scons squashfs-tools subversion
        swig texinfo uglifyjs upx-ucl unzip vim wget xmlto xxd zip zlib1g-dev
    )

    # 记录开始时间
    if [ -z "$PASSWORD" ]; then
        # 每次执行手动输入密码 更新软件包 & 安装依赖
        log INFO 环境 "开始更新软件源"
        sudo DEBIAN_FRONTEND=noninteractive apt update -y
        # sudo DEBIAN_FRONTEND=noninteractive apt full-upgrade -y

        log INFO 环境 "开始安装构建依赖"
        sudo DEBIAN_FRONTEND=noninteractive apt install -y "${packages[@]}"
    else
        # 根据执行脚本只输入一次密码 更新软件包 & 安装依赖
        log INFO 环境 "开始更新软件源"
        echo "$PASSWORD" | sudo -S DEBIAN_FRONTEND=noninteractive apt update -y
        # echo "$PASSWORD" | sudo -S DEBIAN_FRONTEND=noninteractive apt full-upgrade -y

        log INFO 环境 "开始安装构建依赖"
        echo "$PASSWORD" | sudo -S DEBIAN_FRONTEND=noninteractive apt install -y "${packages[@]}"
    fi

    # 下载源码
    # 判断是否存在 openwrt 文件夹，不存在就 git clone 存在就 git pull
    log INFO 源码 "开始准备源码"
    if [ ! -d "openwrt" ]; then

        log INFO 源码 "开始 git clone"
        git clone --depth 1 https://github.com/coolsnowwolf/lede -b master openwrt
        cd openwrt || exit
        log INFO 源码 "git clone 完成"
    else
        cd openwrt || exit
        log INFO 源码 "开始 git pull"
        git pull
        log INFO 源码 "git pull 完成"
    fi

    sed -i '\|^src-git ssrp https://github.com/fw876/helloworld.git;dev$|d' feeds.conf.default
    if [ -d "package/feeds/ssrp" ]; then
        ./scripts/feeds uninstall -a
    fi

    # 更新软件包 & 安装依赖,出现 warning 信息不影响编译
    log INFO feeds "开始更新软件包"
    ./scripts/feeds update -a

    log INFO feeds "开始安装依赖"
    ./scripts/feeds install -a

    log INFO feeds "开始二次安装依赖, 确保安装完整"
    ./scripts/feeds install -a

    # 返回上层目录
    cd ..
    # 打印当前目录
    log INFO 源码 "当前目录"
    pwd

    # 计算所用时间并输出
    timer "$start_time" "更新编译环境依赖及源码"
}

# 如果编译出错才删除临时文件
clean_build_env() {
    if [ ! -d "openwrt" ]; then
        log INFO 清理 "未编译过, 无需清理"
    else
        log INFO 清理 "开始清理, 请耐心等待"

        cd openwrt || exit

        make clean
        make dirclean
        make distclean

        # 删除临时文件
        if [ -z "$PASSWORD" ]; then
            sudo rm -rf tmp
            sudo rm -rf staging_dir
        else
            # 根据执行脚本只输入一次密码 删除临时文件
            echo "$PASSWORD" | sudo rm -rf tmp
            echo "$PASSWORD" | sudo rm -rf staging_dir
        fi

        # 返回上层目录
        cd ..

        log INFO 清理 "清理完毕"

    fi
}

# 编译函数
build_openwrt() {
    local start_time build_jobs
    KERNEL_VERSION=$1
    # 记录开始时间
    start_time=$(date +%s)
    # current_time=$(date "+%Y%m%d%H%M%S")
    # 使用 -d 选项将 Unix 时间戳转换为 YYYYMMDDHHMMSS 格式
    formatted_start_time=$(date -d "@$start_time" "+%Y%m%d%H%M%S")

    make_download "$KERNEL_VERSION"

    # 按选择使用单线程或全部可用线程编译固件.
    # 打印当前目录
    log INFO 编译 "内核 $KERNEL_VERSION: 当前编译目录"
    cd openwrt || exit
    pwd
    log INFO 编译 "内核 $KERNEL_VERSION: 开始编译固件"
    build_jobs=${BUILD_JOBS:-$(nproc)}
    if make -j"$build_jobs"; then
        :
    else
        local result=$?
        log ERROR 编译 "内核 $KERNEL_VERSION: 编译失败, 退出码 $result"
        return "$result"
    fi

    log INFO 编译 "内核 $KERNEL_VERSION: 编译完成"

    # 压缩固件
    log INFO 打包 "内核 $KERNEL_VERSION: 开始打包固件, 当前目录"
    cd ..
    pwd

    # 删除基础镜像
    rm -f ./openwrt/bin/targets/x86/64/openwrt-x86-64-generic-squashfs-rootfs.img.gz

    # 删除 kernel 文件
    rm -f ./openwrt/bin/targets/x86/64/openwrt-x86-64-generic-kernel.bin

    rm -rf ./openwrt/bin/targets/x86/64/packages
    ls -al ./openwrt/bin/targets/x86/64
    # 压缩固件
    # 判断 smb 共享目录:/mnt/resource/openwrt 是否存在
    if [ -d "/mnt/resource/openwrt" ]; then
        # 如果存在就复制到 smb 共享目录
        log INFO 打包 "内核 $KERNEL_VERSION: 开始压缩固件, 当前目录"
        echo "$PASSWORD" | sudo -S zip -r "/mnt/resource/openwrt/openwrt_${KERNEL_VERSION}_${formatted_start_time}.zip" ./openwrt/bin/targets/x86/64
        log INFO 打包 "内核 $KERNEL_VERSION: 打包完成"
        log INFO 产物 "文件: /mnt/resource/openwrt/openwrt_${KERNEL_VERSION}_${formatted_start_time}.zip"
    else
        # 如果不存在就在当前目录
        log INFO 打包 "内核 $KERNEL_VERSION: 开始压缩固件, 当前目录"
        zip -r "openwrt_${KERNEL_VERSION}_${formatted_start_time}.zip" ./openwrt/bin/targets/x86/64
        log INFO 打包 "内核 $KERNEL_VERSION: 打包完成"
        log INFO 产物 "文件: openwrt_${KERNEL_VERSION}_${formatted_start_time}.zip"
    fi
    # 计算所用时间并输出
    timer "$start_time" "版本:$KERNEL_VERSION 编译"
}

# 定义内核版本数组
KERNEL_VERSIONS=("$KERNEL_VERSION_DEFAULT" "6.12" "6.6" "6.1" "5.15" "5.10" "5.4")
BUILD_JOBS=''

# 获取数组长度
length=${#KERNEL_VERSIONS[*]}

start_logging

# 提示用户输入版本
printf "请选择需要编译的内核版本或操作:\n"
for i in $(seq 1 "$length"); do
    printf " %s. 内核版本 %s\n" "$i" "${KERNEL_VERSIONS[$((i - 1))]}"
done
printf " %s. 编译所有版本\n" "$((length + 1))"
printf " %s. 编译失败时,清理编译环境\n" "$((length + 2))"
printf " %s. 单线程编译, 选择内核版本\n" "$((length + 3))"
printf "请选择对应序号,输入 1-%s:" "$((length + 3))"

# 读取用户输入
read -r version_choice

# 单线程模式再次选择内核, 其他选项保持原有并行行为.
if [ "$version_choice" = "$((length + 3))" ]; then
    BUILD_JOBS=1
    printf "请选择单线程编译的内核版本:\n"
    for i in $(seq 1 "$length"); do
        printf " %s. 内核版本 %s\n" "$i" "${KERNEL_VERSIONS[$((i - 1))]}"
    done
    printf " %s. 编译所有版本\n" "$((length + 1))"
    printf "请选择对应序号,输入 1-%s:" "$((length + 1))"
    read -r version_choice
    if [[ ! "$version_choice" =~ ^[1-9][0-9]*$ ]] || ((version_choice > length + 1)); then
        log ERROR 选择 "无效的选择, 退出."
        exit 1
    fi
fi

# 根据用户的输入设置 KERNEL_VERSION 变量
if ((version_choice >= 1 && version_choice <= length)); then
    # 更新编译环境
    update_env_source

    # 编译选择的版本
    build_openwrt "${KERNEL_VERSIONS[$((version_choice - 1))]}"

    # 打印文件列表
    log INFO 产物 "编译完成文件列表:"
    ls -l
    exit 0

elif [ "$version_choice" -eq $((length + 1)) ]; then
    # 记录开始时间
    start_time_all=$(date +%s)
    # 更新编译环境
    update_env_source

    # 编译所有版本
    for version in "${KERNEL_VERSIONS[@]}"; do
        build_openwrt "$version"
    done

    # 打印文件列表
    log INFO 产物 "编译完成文件列表:"
    ls -l

    timer "$start_time_all" "所有版本编译"
    exit 0

elif [ "$version_choice" -eq $((length + 2)) ]; then
    # 记录开始时间
    start_time_all=$(date +%s)

    # 清理编译环境
    clean_build_env

    timer "$start_time_all" "清理编译环境"
    exit 0

else
    log ERROR 选择 "无效的选择, 退出."
    exit 1
fi
