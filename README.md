## Actions for Building OpenWRT


**自助更新:如果 Github Releases 已发布当日固件,请不要多次点击** ***Star*** **以节省公共资源**

测试通过的设备: `d-team_newifi-d2`、`phicomm_k2p`

测试通过的源码: [Lede](https://github.com/coolsnowwolf/lede)

## Github Actions 部署指南(STEP 1):

1. 首先需要获取[Github Token](https://github.com/settings/tokens/new),`Note`项随意填写,`Select scopes`项如果不懂就**全部打勾**,完成后点击`Generate token`

2. 复制页面中显示的 **Token**

   **注意: 一定要保存到本地, Token 值只会显示一次!**

3. ***Fork*** 此仓库,然后进入你的`AutoBuild-Actions`仓库

4. 点击右上方菜单中的`Settings`,点击`Secrets`-`New Secrets`,`Name`项填写`RELEASE_TOKEN`,`Value`项粘贴你在第 2 步中复制的 **Token** 

   **注意: 以上操作只需操作一次!**

## 客制化固件(STEP 2):

1. 进入你的`AutoBuild-Actions`仓库

2. 编辑`/Customize/AutoUpdate.sh`文件,修改`第 7 行`为你的 **设备名称**,修改`第 8 行`为你的 **Github 地址**

3. 编辑`/Sctipts/diy-script.sh`文件,修改`第 7 行`为作者,作者将在 OpenWrt 主页显示

4. **启动编译**: 点击右上方 ***Star*** 即可开始编译,编译详细信息在 `Actions` 中显示

   **二次编译**: 双击右上方 ***Star*** 即可开始编译,最好先同步我的最新改动~~以获得更多特性(bug)~~

   **添加额外的软件包:** 编辑`Scripts/diy-script.sh`中的 `Diy-Part1()` 函数,参照下方语法添加第三方包到源码
```
   [git clone -b]  ExtraPackages git Github仓库 分支
    
   [svn checkout]  ExtraPackages svn Github仓库/trunk
```

   **添加自定义文件:** 首先将文件上传到`/Customize`,然后编辑`Scrips/diy-script.sh`,参照参照现有 `mv2` 语法添加文件到源码中

## 自动编译&&自动升级:

1. 进入你的`AutoBuild-Actions`仓库

2. 编辑`/.github/workflows/AutoBuild.yml`文件,取消注释`第 21-22 行`,并按需修改 corntab 参数

3. 打开 Openwrt 主页,点击`系统`-`定时更新`,设置自动检查升级的时间并保存(**需要 [luci-app-autoupdate](https://github.com/Hyy2001X/luci-app-autoupdate) 支持**)

## 使用指令升级固件:

   一键升级 [Openwrt-AutoUpdate](https://github.com/Hyy2001X/Openwrt-AutoUpdate)
   
   在终端输入: `bash /bin/AutoUpdate.sh`

   不保留配置升级: `bash /bin/AutoUpdate.sh -n`

   使用最新脚本升级: `curl -s https://raw.githubusercontent.com/Hyy2001X/Openwrt-AutoUpdate/master/AutoUpdate.sh | bash`
   
## 鸣谢

   - [Lean's OpenWrt](https://github.com/coolsnowwolf/lede)

   - [P3TERX](https://github.com/P3TERX/Actions-OpenWrt)
   
   - [CurssedCoffin](https://github.com/CurssedCoffin)
   
   - [Licsber](https://github.com/Licsber)
   
   - [mab-wien](https://github.com/mab-wien/openwrt-autoupdate)
   
