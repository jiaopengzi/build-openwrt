#!/bin/bash
###
# @Date         : 2024-02-16 11:03:16
# @Description  : 用于编译 OpenWrt 固件
# @example1     : bash build-openwrt.sh 手动输入密码
# @example2     : bash build-openwrt.sh password 自动输入密码

# 感谢如下大佬的奉献
# coolsnowwolf      https://github.com/coolsnowwolf/lede
# esirplayground    https://github.com/esirplayground/AutoBuild-OpenWrt
# fw876             https://github.com/fw876/helloworld
#
# 还有很多其他大佬，感谢你们的付出。
###

# 设置密码
PASSWORD=$1

# 初始版本
KERNEL_VERSION_DEFAULT="6.6"

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
    echo "======================================== ${event}共计用时: ${hours}时${minutes}分${seconds}秒"
}

# 编译函数
make_download() {
    KERNEL_VERSION=$1
    # 记录开始时间
    start_time=$(date +%s)

    # 打印当前目录
    echo "======================================== 版本:$KERNEL_VERSION 当前下载目录"
    cd openwrt || exit
    pwd

    # 指定内核版本
    sed -i "s/^KERNEL_PATCHVER:=.*$/KERNEL_PATCHVER:=$KERNEL_VERSION/" target/linux/x86/Makefile
    sed -i "s/^KERNEL_TESTING_PATCHVER:=.*$/KERNEL_TESTING_PATCHVER:=$KERNEL_VERSION/" target/linux/x86/Makefile

    echo "======================================== 版本:$KERNEL_VERSION 修改指定内核完成."

    # 删除原来的 .config 文件 自定义定制 - x86_64.config
    echo "======================================== 版本:$KERNEL_VERSION 自定义定制 - x86_64.config"
    rm -f .config
    touch .config

    # 从 x86_64.config 文件中读取配置
    read -r -d '' config <../x86_64.config
    # 将配置写入 .config 文件
    echo "$config" >.config

    # defconfig
    echo "======================================== 版本:$KERNEL_VERSION make defconfig"
    make defconfig

    # 查看编译线程最大值
    echo "======================================== 版本:$KERNEL_VERSION 下载线程数量:$(nproc)"

    # 下载dl库
    echo "======================================== 版本:$KERNEL_VERSION 下载dl库"
    make download -j"$(nproc)"

    # 返回上层目录
    cd ..
    # 计算所用时间并输出
    timer "$start_time" "版本:$KERNEL_VERSION 下载dl库"
}

# 更新编译环境依赖及源码
update_env_source() {

    # 获取网卡名称
    network_card=$(ip -o -4 route show to default | awk '{print $5}')
    # 创建临时文件来存储 debconf 设置
    DEBCONF_TMP=$(mktemp)

    # 写入 debconf 设置到 miniupnpd 配置临时文件
    cat <<EOF >"$DEBCONF_TMP"
miniupnpd miniupnpd/force_igd_desc_v1 boolean false
miniupnpd miniupnpd/iface string $network_card
miniupnpd miniupnpd/ip6script boolean false
miniupnpd miniupnpd/listen string
miniupnpd miniupnpd/start_daemon boolean true
EOF

    start_time=$(date +%s)

    packages=(
        ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential
        bzip2 ccache clang cmake cpio curl device-tree-compiler flex gawk gcc-multilib g++-multilib gettext
        genisoimage git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libfuse-dev libglib2.0-dev
        libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev libpython3-dev
        libreadline-dev libssl-dev libtool llvm lrzsz msmtp ninja-build p7zip p7zip-full patch pkgconf
        python3 python3-pyelftools python3-setuptools qemu-utils rsync scons squashfs-tools subversion
        swig texinfo uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev
    )

    # 记录开始时间
    if [ -z "$PASSWORD" ]; then
        # 每次执行手动输入密码 更新软件包 & 安装依赖
        sudo apt update -y
        sudo apt full-upgrade -y

        # 预先配置 miniupnpd 的 debconf 设置 解决安装 miniupnpd 交互无法输入问题
        sudo apt install debconf-utils -y
        sudo cat "$DEBCONF_TMP" | sudo debconf-set-selections

        sudo apt install -y "${packages[@]}"
    else
        # 根据执行脚本只输入一次密码 更新软件包 & 安装依赖
        echo "$PASSWORD" | sudo -S apt update -y
        echo "$PASSWORD" | sudo -S apt full-upgrade -y

        # 预先配置 miniupnpd 的 debconf 设置 解决安装 miniupnpd 交互无法输入问题
        echo "$PASSWORD" | sudo -S apt install debconf-utils -y
        echo "$PASSWORD" | sudo -S cat "$DEBCONF_TMP" | sudo -S debconf-set-selections

        echo "$PASSWORD" | sudo -S apt install -y "${packages[@]}"

    fi

    # 下载源码
    # 判断是否存在 openwrt 文件夹，不存在就 git clone 存在就 git pull
    echo "======================================== 下载源码"
    if [ ! -d "openwrt" ]; then

        git clone --depth 1 https://github.com/coolsnowwolf/lede -b master openwrt
        cd openwrt || exit
        echo "======================================== git clone"

        # 添加 ssrp 源
        echo "src-git ssrp https://github.com/fw876/helloworld.git" >>./feeds.conf.default
    else
        cd openwrt || exit
        git pull
        echo "======================================== git pull"
    fi

    # 更新软件包 & 安装依赖,出现 warning 信息不影响编译
    echo "======================================== 更新软件包"
    ./scripts/feeds update -a

    echo "======================================== 安装依赖"
    ./scripts/feeds install -a

    echo "======================================== 二次安装依赖,确保安装完整"
    ./scripts/feeds install -a

    # 返回上层目录
    cd ..
    # 打印当前目录
    echo "======================================== 当前目录"
    pwd

    # 初次下载dl库
    make_download "$KERNEL_VERSION_DEFAULT"

    # 删除临时文件
    rm -f "$DEBCONF_TMP"

    # 计算所用时间并输出
    timer "$start_time" "更新编译环境依赖及源码"
}

# 如果编译出错才删除临时文件
clean_build_env() {
    if [ ! -d "openwrt" ]; then
        echo "======================================== 未编译过，无需清理"
    else
        echo "======================================== 开始清理,请耐心等待"

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

        echo "======================================== 清理完毕"

    fi
}

# 编译函数
build_openwrt() {
    KERNEL_VERSION=$1
    # 记录开始时间
    start_time=$(date +%s)
    # current_time=$(date "+%Y%m%d%H%M%S")
    # 使用 -d 选项将 Unix 时间戳转换为 YYYYMMDDHHMMSS 格式
    formatted_start_time=$(date -d "@$start_time" "+%Y%m%d%H%M%S")

    make_download "$KERNEL_VERSION"

    # 编译固件 稳妥起见，使用单线程编译
    # 打印当前目录
    echo "======================================== 版本:$KERNEL_VERSION 当前编译目录"
    cd openwrt || exit
    pwd
    echo "======================================== 版本:$KERNEL_VERSION 开始编译固件"
    make -j"$(nproc)"
    # make V=s -j1

    echo "======================================== 版本:$KERNEL_VERSION 编译完成"

    # 压缩固件
    echo "======================================== 版本:$KERNEL_VERSION 开始打包固件,当前目录"
    cd ..
    pwd

    # 删除基础镜像
    rm -f ./openwrt/bin/targets/x86/64/openwrt-x86-64-generic-squashfs-rootfs.img.gz

    # 删除 kernel 文件
    rm -f ./openwrt/bin/targets/x86/64/openwrt-x86-64-generic-kernel.bin

    # 压缩固件
    # 判断 smb 共享目录:/mnt/resource/openwrt 是否存在
    if [ -d "/mnt/resource/openwrt" ]; then
        # 如果存在就复制到 smb 共享目录
        echo "======================================== 版本:$KERNEL_VERSION 开始压缩固件,当前目录"
        echo "$PASSWORD" | sudo -S zip -r "/mnt/resource/openwrt/openwrt_${KERNEL_VERSION}_${formatted_start_time}.zip" ./openwrt/bin/targets/x86/64
        echo "======================================== 版本:$KERNEL_VERSION 打包完成"
        echo "文件:/mnt/resource/openwrt/openwrt_${KERNEL_VERSION}_${formatted_start_time}.zip"
    else
        # 如果不存在就在当前目录
        echo "======================================== 版本:$KERNEL_VERSION 开始压缩固件,当前目录"
        zip -r "openwrt_${KERNEL_VERSION}_${formatted_start_time}.zip" ./openwrt/bin/targets/x86/64
        echo "======================================== 版本:$KERNEL_VERSION 打包完成"
        echo "文件:openwrt_${KERNEL_VERSION}_${formatted_start_time}.zip"
    fi
    # 计算所用时间并输出
    timer "$start_time" "版本:$KERNEL_VERSION 编译"
}

# 定义内核版本数组
KERNEL_VERSIONS=("$KERNEL_VERSION_DEFAULT" "6.1" "5.15" "5.10" "5.4")

# 获取数组长度
length=${#KERNEL_VERSIONS[*]}

# 提示用户输入版本
printf "请选择需要编译的内核版本或操作:\n"
for i in $(seq 1 "$length"); do
    printf " %s. 内核版本 %s\n" "$i" "${KERNEL_VERSIONS[$((i - 1))]}"
done
printf " %s. 编译所有版本\n" "$((length + 1))"
printf " %s. 编译失败时,清理编译环境\n" "$((length + 2))"
printf "请选择对应序号,输入 1-%s:" "$((length + 2))"

# 读取用户输入
read -r version_choice

# 根据用户的输入设置 KERNEL_VERSION 变量
if ((version_choice >= 1 && version_choice <= length)); then
    # 更新编译环境
    update_env_source

    # 编译选择的版本
    build_openwrt "${KERNEL_VERSIONS[$((version_choice - 1))]}"

    # 打印文件列表
    echo "======================================== 编译完成文件列表:"
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
    echo "======================================== 编译完成文件列表:"
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
    echo "无效的选择，退出."
    exit 1
fi
