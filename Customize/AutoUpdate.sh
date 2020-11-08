#!/bin/bash
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001
# AutoUpdate

Version=V3.9
DEFAULT_DEVICE=d-team_newifi-d2
Github=https://github.com/xbfree/AutoBuild-Actions

TIME() {
	echo -ne "\n[$(date "+%H:%M:%S")] "
}

Github_Download=$Github/releases/download/AutoUpdate
Author=${Github##*com/}
Github_Tags=https://api.github.com/repos/$Author/releases/latest
cd /etc
CURRENT_VERSION=$(awk 'NR==1' ./openwrt_info)
CURRENT_DEVICE=$(jsonfilter -e '@.model.id' < "/etc/board.json" | tr ',' '_')
clear && echo "Openwrt-AutoUpdate Script $Version"
if [[ -z "$1" ]];then
	Upgrade_Option="-q" && TIME && echo "执行: 保留配置升级"
else
	Upgrade_Option="$1"
	[ "$Upgrade_Option" == "-n" ] && TIME && echo "执行: 不保留配置升级"
	if [ "$Upgrade_Option" == "-x" ];then
		Upgrade_Option="-q"
		Force_Update=1
		TIME && echo "执行: 保留配置强制升级"
	fi
fi
opkg list | awk  '{print $1}' > /tmp/Package_list
grep "curl" /tmp/Package_list > /dev/null 2>&1
if [ ! $? -ne 0 ];then
	Google_Check=$(curl -I -s --connect-timeout 5 www.google.com -w %{http_code} | tail -n1)
	[ ! "$Google_Check" == 200 ] && TIME && echo "Google 连接失败,可能导致固件下载速度缓慢!"
fi
grep "wget" /tmp/Package_list > /dev/null 2>&1
if [ $? -ne 0 ];then
	TIME && read -p "未安装 wget,是否执行安装?[Y/n]:" Choose
	if [ $Choose == Y ] || [ $Choose == y ];then
		TIME && echo -e "开始安装 wget,请耐心等待...\n"
		opkg update > /dev/null 2>&1
		opkg install wget
	else
		TIME &&  echo "用户已取消安装,即将退出更新程序..."
		sleep 2
		exit
	fi
fi
if [[ -z "$CURRENT_VERSION" ]];then
	echo -e "\n警告:当前固件版本获取失败!"
	CURRENT_VERSION=未知
fi
if [[ -z "$CURRENT_DEVICE" ]];then
	echo -e "\n警告:当前设备名称获取失败,使用预设名称[$DEFAULT_DEVICE]"
	CURRENT_DEVICE=$DEFAULT_DEVICE
fi
TIME && echo "正在检查更新..."
[ ! -f /tmp/Github_Tags ] && touch /tmp/Github_Tags
wget -q $Github_Tags -O - > /tmp/Github_Tags
GET_FullVersion=$(cat /tmp/Github_Tags | egrep -o "AutoBuild-$CURRENT_DEVICE-Lede-R[0-9]+.[0-9]+.[0-9]+.[0-9]+" | awk 'END {print}')
GET_Version="${GET_FullVersion#*Lede-}"
if [[ -z "$GET_FullVersion" ]] || [[ -z "$GET_Version" ]];then
	TIME && echo "检查更新失败,请稍后重试!"
	exit
fi
echo -e "\n固件作者: ${Author%/*}"
echo "设备名称: $DEFAULT_DEVICE"
echo -e "\n当前固件版本:$CURRENT_VERSION"
echo -e "云端固件版本:$GET_Version\n"
if [[ ! $Force_Update == 1 ]];then
	if [ $CURRENT_VERSION == $GET_Version ];then
		TIME && read -p "已是最新版本,是否强制更新固件?[Y/n]:" Choose
		if [ $Choose == Y ] || [ $Choose == y ];then
			TIME && echo -e "开始强制更新固件...\n"
		else
			TIME &&  echo "用户已取消强制更新,即将退出更新程序..."
			sleep 2
			exit
		fi
	fi
fi
Firmware_Info="$GET_FullVersion"
Firmware="${Firmware_Info}.bin"
Firmware_Detail="${Firmware_Info}.detail"
echo "云端固件名称:$Firmware"
cd /tmp
TIME && echo "正在下载固件,请耐心等待..."
wget -q $Github_Download/$Firmware -O $Firmware
if [ ! $? == 0 ]; then
	TIME && echo "下载失败,请检查网络后重试!"
	exit
fi
TIME && echo "下载成功!固件大小:$(du -h $Firmware | awk '{print $1}')B"
TIME && echo "正在下载固件详细信息..."
wget -q $Github_Download/$Firmware_Detail -O $Firmware_Detail
if [ ! $? == 0 ]; then
	TIME && echo "下载失败,请检查网络后重试!"
	exit
fi
GET_MD5=$(awk -F'[ :]' '/MD5/ {print $2;exit}' $Firmware_Detail)
CURRENT_MD5=$(md5sum $Firmware | cut -d ' ' -f1)
echo -e "\n当前固件MD5:$CURRENT_MD5"
echo "云端固件MD5:$GET_MD5"
if [[ -z "$GET_MD5" ]] || [[ -z "$CURRENT_MD5" ]];then
	echo -e "\nMD5获取失败!"
	exit
fi
if [ ! "$GET_MD5" == "$CURRENT_MD5" ];then
	echo -e "\nMD5对比失败,请检查网络后重试!"
	exit
fi
TIME && echo -e "开始升级固件,请耐心等待...\n"
sleep 3
sysupgrade ${Upgrade_Option} $Firmware
