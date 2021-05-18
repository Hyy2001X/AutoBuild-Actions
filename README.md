# Actions for Building OpenWrt / AutoUpdate

![GitHub Stars](https://img.shields.io/github/stars/Hyy2001X/AutoBuild-Actions.svg?style=flat-square&label=Stars&logo=github)
![GitHub Forks](https://img.shields.io/github/forks/Hyy2001X/AutoBuild-Actions.svg?style=flat-square&label=Forks&logo=github)

测试通过的设备: `d-team_newifi-d2`、`xiaoyu_xy-c5`、`x86_64(img、img.gz)`

测试通过的源码: `coolsnowwolf/lede:master`、`immortalwrt/immortalwrt`、`openwrt/openwrt`

## 部署环境(STEP 1):

1. 首先需要获取 **Github Token**: [点击这里](https://github.com/settings/tokens/new) 获取,

   `Note`项填写一个名称,`Select scopes`**全部打勾**,完成后点击下方`Generate token`

2. 复制页面中生成的 **Token**,**并保存到本地,Token 只会显示一次!**

3. **Fork** 我的`AutoBuild-Actions`仓库,然后进入你的`AutoBuild-Actions`仓库进行之后的设置

4. 点击上方菜单中的`Settings`,依次点击`Secrets`-`New repository secret`

   其中`Name`项随意填写,然后将你的 **Token** 粘贴到`Value`项,完成后点击`Add secert`

## 定制固件(STEP 2):

1. 进入你的`AutoBuild-Actions`仓库,**下方所有操作都将在你的`AutoBuild-Actions`仓库下进行**

2. 把本地的 `.config` 文件重命名为你的**设备名称**并上传到`/Configs`目录

3. 编辑`.github/workflows/*.yml`文件,修改`第 9 和 29 行`为你的**设备名称**

   **更换源码与分支** 修改`第 30 行 REPO_URL:`为源码仓库地址,`第 31 行`为分支 (可选)

4. 按照需求编辑并定制`Scripts/AutoBuild_DiyScript.sh`文件

   **注意: 为了更方便地同步我的改动,不建议修改 Scripts/AutoBuild_Function.sh 文件**

   **第三方软件包列表** 编辑`CustomPackages`目录下对应**设备名称**的文件,按照现有语法为该设备添加第三方软件包 (可选)

**AutoBuild_DiyScript.sh: Diy_Core() 函数中的变量解释:**
```
   Author 作者名称,若该项留空将自动设置为你的 Github 用户名

   Default_Device 设备的官方名称,例如 d-team_newifi-d2、x86_64
   
   Short_Firmware_Date 固件日期样式,当设置为 true: [20210501] false: [202105012300]
   
   Default_IP_Address 固件 LAN IP 地址,默认为: [192.168.1.1] false: [不做任何修改]

   INCLUDE_AutoUpdate 启用后,将自动添加 Scripts/AutoUpdate.sh 和 luci-app-autoupdate 到固件

   INCLUDE_AutoBuild_Tools 添加 AutoBuild 工具箱: AutoBuild_Tools.sh 到固件

   INCLUDE_DRM_I915 自动启用 Intel Graphics 驱动 (测试特性)

   INCLUDE_Theme_Argon 自动添加适用于当前源码的 luci-theme-argon 主题

   INCLUDE_Obsolete_PKG_Compatible 优化原生 OpenWrt-19.07、21.02 支持 (测试特性)
   
   注: 若要启用某项功能,请将该值修改为 true,禁用某项功能则修改为 false 或留空
```
**其他指令:** 编辑`Scripts/AutoBuild_DiyScript.sh`,参照下方语法:
```
   [使用 git clone 拉取文件]  AddPackage git 存放位置 软件包名 仓库地址 分支

   [使用 svn co 拉取文件]  AddPackage svn 存放位置 软件包名 仓库地址/branches/分支/路径

   [替换 /CustomFiles 文件到源码] Replace_File 文件(夹)名称 目标路径 新名称[可选]
   
   [查找文件/文件夹] PKG_Finder f/d(文件/文件夹) 文件(夹)名称 查找路径
```
## 编译固件(STEP 3):

   **一键编译** 先删除`第 26-27 行`的注释并保存,单(双)击重新点亮右上角的 **Star** 即可一键编译

   **定时编译** 先删除`第 23-24 行`的注释,然后按需修改相关参数并保存,[使用方法](https://www.runoob.com/w3cnote/linux-crontab-tasks.html)

   **手动编译** 点击上方`Actions`,选择你要编译的设备名称,点击右方`Run workflow`,点击绿色按钮即可开始编译
   
   **临时修改 IP 地址** 该功能仅在**手动编译**时生效,点击`Run workflow`后即可输入 IP 地址(优先级**高于** Diy_Core 函数)

   **SSH 连接** 使用方法参见 [P3TERX's Blog](https://p3terx.com/archives/build-openwrt-with-github-actions.html)

## 使用 AutoUpdate 一键更新脚本:

   首先需要打开`TTYD 终端`或者在浏览器输入`IP 地址:7681`,按需输入下方指令:

   检查并更新固件(保留配置),输入: `autoupdate`或`bash /bin/AutoUpdate.sh`

   更新固件(FastGit 镜像加速): `autoupdate -p`

   更新固件(不保留配置): `autoupdate -n`或`autoupdate -np`

   查看更多使用方法: `autoUpdate -h`

   **注意: 该功能需要在 Diy-Core() 函数中设置`INCLUDE_AutoUpdate`为`true`**

## 使用 AutoBuild 固件工具箱:

   打开`TTYD 终端`,输入`tools`或`bash /bin/AutoBuild_Tools.sh`,请自行摸索,功能持续开发中...

   **注意: 该功能需要在 Diy-Core() 函数中设置`INCLUDE_AutoBuild_Tools`为`true`**

## 鸣谢

   - [Lean's Openwrt Source code](https://github.com/coolsnowwolf/lede)

   - [P3TERX's Actions-OpenWrt Project](https://github.com/P3TERX/Actions-OpenWrt)

   - [P3TERX's Blog](https://p3terx.com/archives/build-openwrt-with-github-actions.html)

   - [ImmortalWrt](https://github.com/immortalwrt)

   - [eSir's workflow](https://github.com/esirplayground/AutoBuild-OpenWrt/blob/master/.github/workflows/Build_OP_x86_64.yml)

   - 测试与建议: [CurssedCoffin](https://github.com/CurssedCoffin) [Licsber](https://github.com/Licsber) [sirliu](https://github.com/sirliu) [teasiu](https://github.com/teasiu)
