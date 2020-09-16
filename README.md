# AutoBuild-Actions
Actions for Building OpenWRT

Supported Devices: `d-team_newifi-d2`

# 配置.config文件
1. 首先装好 Ubuntu 64bit，推荐  Ubuntu  18 LTS x64

2. 命令行输入 `sudo apt-get update` ，然后输入
`
sudo apt-get -y install build-essential asciidoc binutils bzip2 gawk gettext git libncurses5-dev libz-dev patch python3 python2.7 unzip zlib1g-dev lib32gcc1 libc6-dev-i386 subversion flex uglifyjs git-core gcc-multilib p7zip p7zip-full msmtp libssl-dev texinfo libglib2.0-dev xmlto qemu-utils upx libelf-dev autoconf automake libtool autopoint device-tree-compiler g++-multilib antlr3 gperf wget curl swig rsync
`

3. 使用 `git clone https://github.com/coolsnowwolf/lede` 命令下载好源代码
4. 然后 `cd lede` `cd package` 进入包目录，安装第三方包以及passwall依赖 `git clone https://github.com/kenzok8/openwrt-packages.git git clone https://github.com/kenzok8/small.git` 然后 `cd` `cd lede` 进入lede目录

5. ```bash
   ./scripts/feeds update -a
   ./scripts/feeds install -a
   ```
6. ```bash
   make menuconfig
   ```

