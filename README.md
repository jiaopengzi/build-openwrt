# build-openwrt


感谢如下大佬的奉献



- coolsnowwolf      https://github.com/coolsnowwolf/lede
- esirplayground    https://github.com/esirplayground/AutoBuild-OpenWrt
- fw876             https://github.com/fw876/helloworld

    

还有很多其他大佬，感谢你们的付出。

**此脚本只适配了 x86 的机器,其他机器未适配。**

## 一、本地编译

### 1、编译环境

**注意编译全程需要全局走梯子**

编译环境使用 `Ubuntu 22.04 LTS` `Ubuntu 24.04 LTS`  `Debian 11.10` 均可正常编译，建议使用`Ubuntu 24.04 LTS`；其他版本未测试，请酌情使用

**已经移除了 `python2.7`**

**注意** 编译过程中会使用 `apt upgrade` 请不要使用生产中的机器来编译。



- **不要用 root 用户进行编译**

- 国内用户编译前最好准备好梯子，编译机器使用全局模式。

- 默认登陆IP 192.168.1.1 密码 password



在`build-openwrt.sh`中，如下参数可以根据自身机器容量来修改，单位(M)。

默认是 256M 和 1024M.

```
CONFIG_TARGET_KERNEL_PARTSIZE=256
CONFIG_TARGET_ROOTFS_PARTSIZE=1024
```


### 2、自动编译


下载脚本到本地

```shell
wget https://github.com/jiaopengzi/build-openwrt/raw/main/build-openwrt.sh
```


对脚本添加执行权限，调用脚本执行编译

```shell
sudo chmod +x build-openwrt.sh
./build-openwrt.sh your-password
```



明文输入密码有风险，但可以后续无人值守编译。



也可以使用`./build-openwrt.sh`,这需要根据提示输入用户密码，不能实现无人值守。



执行脚本示例：

```shell
u01@debian-11:~$ ./build-openwrt.sh 
请选择需要编译的内核版本或操作:
 1. 内核版本 6.6
 2. 内核版本 6.1
 3. 内核版本 5.15
 4. 内核版本 5.10
 5. 内核版本 5.4
 6. 编译所有版本
 7. 编译失败时,清理编译环境
请选择对应序号,输入 1-7:
```



可以根据自己需求选择内核版本，目前我使用的是 6.6 的内核，稳定运行半年以上了。



## 二、线上 github actions 编译

1. 将本仓库 fork 到自己的仓库
2. 在 `./.github/workflows/build.yaml` 中去修改一下 `@BuildDate    : 2024-10-26 09:47:21` 中的日期，执行 push 后，就可以看到编译在执行了。当然也可以手动去执行 `run wokflow`。
3. 等待一段时间后，回来可以看到编译好固件就生成了，下载下来执行后续步骤即可。



线上编译默认版本是`6.6`，如果需要修改可以修改 `./.github/workflows/build.yaml` 如下内容：

```
KERNEL_VERSION: '6.6' # 可选内核版本 6.6 | 6.1 | 5.15 | 5.10 | 5.4
```

对应配置文件 `x86_64.config` 可以根据自己需求修改.


## 三、编译后安装固件

1. 编译后目标文件存在路径和脚本同目录如：`openwrt_6.6_xxx.zip`

2. 解压后cd到`./openwrt/bin/targets/x86/64/`查看编译好的固件。

3. 将`openwrt-x86-64-generic-squashfs-combined-efi.img.gz` 解压为`img`文件。

4. 使用 ventoy(https://www.ventoy.net/cn/index.html) 作为安装镜像工具

5. 准备写盘工具`DiskImage_1_6_WinAll.exe` https://roadkil.net/program.php/P12/Disk%20Image

6. 使用 iso 版本的 winpe(https://www.wepe.com.cn/download.html)

7. 将 openwrt 固件存放到 U 盘

8. 在 winpe 环境下，格式化需要写入固件的硬盘，删除所有分区(**提前备份硬盘中需要的内容**)。

9. 使用 `DiskImage_1_6_WinAll.exe` 将编译的固件写入硬盘。

10. 重启后，使用 ssh 进入 openwrt 的后台，修改`/etc/config/network`ip配置, 默认登陆IP `192.168.1.1`, 用户：`root`, 密码`password`.

    ```shell
    vim /etc/config/network
    ```

11. 接下来就可以愉快的上网冲浪了。



## 声明

本项目在遵守当地法律前提下，只作为学习使用，不作其他用途。