#!/bin/bash
###
# @Date         : 2024-02-16 11:03:16
# @Description  : 用于编译 OpenWrt 固件
# @example1     : bash build-openwrt.sh 手动输入密码
# @example2     : bash build-openwrt.sh password 自动输入密码

# 感谢如下大佬的奉献
# coolsnowwolf      https://github.com/coolsnowwolf/lede
# esirplayground    https://github.com/esirplayground/AutoBuild-OpenWrt
# fw876             https://github.com/fw876/helloworld.git
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
    cat >>.config <<EOF
# x86_64.config
CONFIG_TARGET_x86=y
CONFIG_TARGET_x86_64=y
CONFIG_TARGET_KERNEL_PARTSIZE=256
CONFIG_TARGET_ROOTFS_PARTSIZE=1024

CONFIG_KERNEL_BUILD_USER="jpz"
CONFIG_GRUB_TITLE="OpenWrt Build by jiaopengzi"
# CONFIG_GRUB_CONSOLE is not set

# 编译固件输出格式
CONFIG_GRUB_EFI_IMAGES=y
CONFIG_TARGET_IMAGES_GZIP=y

# vmware 虚拟机镜像
# CONFIG_VMDK_IMAGES is not set

# iso 镜像
# CONFIG_ISO_IMAGES is not set

# PVE/KVM 镜像 CONFIG_QCOW2_IMAGES is not set
# CONFIG_QCOW2_IMAGES is not set

# virtualbox 镜像
# CONFIG_VDI_IMAGES is not set

# hyper-v 镜像
# CONFIG_VHDX_IMAGES is not set

CONFIG_PACKAGE_grub2-efi=y
CONFIG_PACKAGE_dnsmasq_full_auth=y
CONFIG_PACKAGE_dnsmasq_full_conntrack=y
CONFIG_PACKAGE_dnsmasq_full_dnssec=y
CONFIG_PACKAGE_ddns-scripts_cloudflare.com-v4=y
CONFIG_PACKAGE_ddns-scripts_freedns_42_pl=y
CONFIG_PACKAGE_ddns-scripts_godaddy.com-v1=y
CONFIG_PACKAGE_ddns-scripts_no-ip_com=y
CONFIG_PACKAGE_ddns-scripts_nsupdate=y
CONFIG_PACKAGE_ddns-scripts_route53-v1=y
CONFIG_PACKAGE_curl=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_wget-nossl=y
CONFIG_PACKAGE_wget-ssl=y
CONFIG_PACKAGE_kmod-kvm-amd=y
CONFIG_PACKAGE_kmod-kvm-intel=y
CONFIG_PACKAGE_kmod-kvm-x86=y
CONFIG_PACKAGE_kmod-usb-ohci=y
CONFIG_PACKAGE_kmod-usb-ohci-pci=y
CONFIG_PACKAGE_kmod-usb-storage-uas=y
CONFIG_PACKAGE_kmod-usb-uhci=y
CONFIG_PACKAGE_kmod-sdhci=y
CONFIG_PACKAGE_kmod-usb2=y
CONFIG_PACKAGE_kmod-usb2-pci=y
CONFIG_PACKAGE_kmod-usb3=y
# CONFIG_PACKAGE_luci-theme-argon is not set
# CONFIG_PACKAGE_luci-app-ttyd is not set
CONFIG_PACKAGE_luci-app-frpc=y
CONFIG_PACKAGE_luci-app-diag-core=y
CONFIG_PACKAGE_upx=y
CONFIG_PACKAGE_lsblk=y

# openssl
CONFIG_OPENSSL_WITH_CAMELLIA=y
CONFIG_OPENSSL_WITH_COMPRESSION=y
CONFIG_OPENSSL_WITH_DTLS=y
CONFIG_OPENSSL_WITH_EC2M=y
CONFIG_OPENSSL_WITH_ERROR_MESSAGES=y
CONFIG_OPENSSL_WITH_IDEA=y
CONFIG_OPENSSL_WITH_MDC2=y
CONFIG_OPENSSL_WITH_RFC3779=y
CONFIG_OPENSSL_WITH_SEED=y
CONFIG_OPENSSL_WITH_WHIRLPOOL=y

# openssl 安装
CONFIG_PACKAGE_luci-app-openvpn=y
CONFIG_PACKAGE_luci-app-openvpn-server=y
CONFIG_PACKAGE_openvpn-easy-rsa=y
CONFIG_PACKAGE_openvpn-openssl=y

# ssl证书获取
CONFIG_PACKAGE_acme=y
CONFIG_PACKAGE_acme-deploy=y
CONFIG_PACKAGE_acme-dnsapi=y
CONFIG_PACKAGE_acme-notify=y
CONFIG_PACKAGE_luci-app-acme=y

# ssrp 配置
CONFIG_DEFAULT_luci-app-ssr-plus=y
CONFIG_PACKAGE_luci-app-ssr-plus=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_libustream-openssl=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_NONE_Client=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Libev_Client=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Rust_Client=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_NONE_Server=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Libev_Server=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Rust_Server=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_V2ray=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Xray=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_ChinaDNS_NG=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_MosDNS=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Hysteria=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Tuic_Client=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadow_TLS=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_IPT2Socks=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Kcptun=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_NaiveProxy=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Redsocks2=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_Simple_Obfs=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Shadowsocks_V2ray_Plugin=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_ShadowsocksR_Libev_Client=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_ShadowsocksR_Libev_Server=y
CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_Trojan=y
CONFIG_PACKAGE_luci-i18n-ssr-plus-zh-cn=y

# 磁盘管理工具
CONFIG_PACKAGE_luci-app-diskman=y
CONFIG_PACKAGE_luci-app-diskman_INCLUDE_btrfs_progs=y
CONFIG_PACKAGE_luci-app-diskman_INCLUDE_lsblk=y
CONFIG_PACKAGE_luci-app-diskman_INCLUDE_mdadm=y

# docker 后台使用命令行
CONFIG_PACKAGE_dockerd=y
CONFIG_PACKAGE_docker=y
CONFIG_PACKAGE_docker-compose=y

# ssh vim
CONFIG_PACKAGE_openssh-sftp-server=y
CONFIG_PACKAGE_vim-full=y

# 广告过滤
CONFIG_PACKAGE_adbyby=y

EOF

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
    start_time=$(date +%s)
    # 记录开始时间
    if [ -z "$PASSWORD" ]; then
        # 每次执行手动输入密码 更新软件包 & 安装依赖
        sudo apt update -y
        sudo apt full-upgrade -y
        sudo apt install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
            bzip2 ccache cmake cpio curl device-tree-compiler fastjar flex gawk gettext gcc-multilib g++-multilib \
            git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libfuse-dev libglib2.0-dev libgmp3-dev \
            libltdl-dev libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev libpython3-dev libreadline-dev \
            libssl-dev libtool lrzsz mkisofs msmtp ninja-build p7zip p7zip-full patch pkgconf python3 \
            python3-pyelftools python3-setuptools qemu-utils rsync scons squashfs-tools subversion swig texinfo \
            uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev \
            make clang llvm nano python3-pip aria2 \
            bc lm-sensors pciutils curl miniupnpd conntrack conntrackd jq liblzma-dev \
            libpcre2-dev libpam0g-dev libkmod-dev libtirpc-dev libaio-dev libcurl4-openssl-dev libtins-dev libyaml-cpp-dev libglib2.0-dev libgpiod-dev
    else
        # 根据执行脚本只输入一次密码 更新软件包 & 安装依赖
        echo "$PASSWORD" | sudo -S apt update -y
        echo "$PASSWORD" | sudo -S apt full-upgrade -y
        echo "$PASSWORD" | sudo -S apt install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
            bzip2 ccache cmake cpio curl device-tree-compiler fastjar flex gawk gettext gcc-multilib g++-multilib \
            git gperf haveged help2man intltool libc6-dev-i386 libelf-dev libfuse-dev libglib2.0-dev libgmp3-dev \
            libltdl-dev libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev libpython3-dev libreadline-dev \
            libssl-dev libtool lrzsz mkisofs msmtp ninja-build p7zip p7zip-full patch pkgconf python3 \
            python3-pyelftools python3-setuptools qemu-utils rsync scons squashfs-tools subversion swig texinfo \
            uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev \
            make clang llvm nano python3-pip aria2 \
            bc lm-sensors pciutils curl miniupnpd conntrack conntrackd jq liblzma-dev \
            libpcre2-dev libpam0g-dev libkmod-dev libtirpc-dev libaio-dev libcurl4-openssl-dev libtins-dev libyaml-cpp-dev libglib2.0-dev libgpiod-dev

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
