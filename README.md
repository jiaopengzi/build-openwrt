# build-openwrt
## 声明本项目只作为学习使用，不作为其他用途。



感谢如下大佬的奉献
coolsnowwolf      https://github.com/coolsnowwolf/lede
esirplayground    https://github.com/esirplayground/AutoBuild-OpenWrt
fw876             https://github.com/fw876/helloworld.git

还有很多其他大佬，感谢你们的付出。



## 1、编译环境

编译环境使用 `Ubuntu 22.04 LTS` `Debian 11.10` 均可正常编译，建议使用`Ubuntu 22.04 LTS`；其他版本未测试，请酌情使用。

**注意** 编译过程中会使用 `apt upgrade` 请不要使用生产中的机器来编译。



- **不要用 root 用户进行编译**

- 国内用户编译前最好准备好梯子，编译机器使用全局模式。

- 默认登陆IP 192.168.1.1 密码 password



在`build_openwrt.sh`中，如下参数可以根据自身机器容量来修改，单位(M)。

默认是 256M 和 1024M.

```
CONFIG_TARGET_KERNEL_PARTSIZE=256
CONFIG_TARGET_ROOTFS_PARTSIZE=1024
```



**此脚本只适配了 x86 的机器,其他机器未适配。**



## 2、自动编译

下载脚本到本地

```bash
wget https://github.com/jiaopengzi/build-openwrt/raw/main/build-openwrt.sh
```



执行编译

```bash
bash build_openwrt.sh password
```

明文输入密码有风险，但可以后续无人值守编译。



也可以使用`bash build_openwrt.sh`,这需要根据提示输入用户密码，不能实现无人值守。



执行脚本示例：

```shell
u01@debian-11:~$ bash build_openwrt.sh passwrod
请选择需要编译的内核版本:
 1. 内核版本 6.1
 2. 内核版本 5.15
 3. 内核版本 5.10
 4. 内核版本 5.4
 5. 编译所有版本
请选择版本对应序号,输入 1-5:5
```



可以根据自己需求选择内核版本，目前我使用的是 6.1 的内核，稳定运行半年以上了。



## 4、编译后安装固件

1. 编译后目标文件存在路径和脚本同目录如：`openwrt_6.1_xxx.zip`

2. 解压后cd到`./openwrt/bin/targets/x86/64/`查看编译好的固件。

3. 将`openwrt-x86-64-generic-squashfs-combined-efi.img.gz` 解压为`img`文件。

4. 使用 ventoy(https://www.ventoy.net/cn/index.html) 作为安装镜像工具

5. 准备写盘工具`DiskImage_1_6_WinAll.exe` https://roadkil.net/program.php/P12/Disk%20Image

6. 使用 iso 版本的 winpe(https://www.wepe.com.cn/download.html)

7. 将 openwrt 固件存放到 U 盘

8. 在 winpe 环境下，格式化需要写入固件的硬盘，删除所有分区(**提前备份硬盘中需要的内容**)。

9. 使用 `DiskImage_1_6_WinAll.exe` 将编译的固件写入硬盘。

10. 重启后，使用 ssh 进入 openwrt 的后台，修改ip, 默认登陆IP `192.168.1.1`, 用户：`root`, 密码`password`.

    ```shell
    viM /etc/config/network
    ```

11. 接下来就可以愉快的上网冲浪了。

