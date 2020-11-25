#!/bin/bash
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001
# AutoBuild Actions

Diy_Core() {
Author=XuBin
Default_Device=d-team_newifi-d2

AutoUpdate_Version=`awk 'NR==6' ./package/base-files/files/bin/AutoUpdate.sh | awk -F'[="]+' '/Version/{print $2}'`
Compile_Date=`date +'%Y/%m/%d'`
Compile_Time=`date +'%Y-%m-%d %H:%M:%S'`
Default_File=./package/lean/default-settings/files/zzz-default-settings
Lede_Version=`egrep -o "R[0-9]+\.[0-9]+\.[0-9]+" $Default_File`
Openwrt_Version="$Lede_Version-`date +%Y%m%d`"
}

GET_TARGET_INFO() {
Diy_Core
TARGET_PROFILE=`egrep -o "CONFIG_TARGET.*DEVICE.*=y" .config | sed -r 's/.*DEVICE_(.*)=y/\1/'`
[ -z $TARGET_PROFILE ] && TARGET_PROFILE=$Default_Device
TARGET_BOARD=`awk -F'[="]+' '/TARGET_BOARD/{print $2}' .config`
TARGET_SUBTARGET=`awk -F'[="]+' '/TARGET_SUBTARGET/{print $2}' .config`
}

ExtraPackages() {
[ -d ./package/lean/$2 ] && rm -rf ./package/lean/$2
[ -d ./$2 ] && rm -rf ./$2
Retry_Times=3
while [ ! -f $2/Makefile ]
do
	echo "[$(date "+%H:%M:%S")] Checking out $2 from $3 ..."
	case $1 in
	git)
		git clone -b $4 $3/$2 $2 > /dev/null 2>&1
	;;
	svn)
		svn checkout $3/$2 $2 > /dev/null 2>&1
	esac
	if [ -f $2/Makefile ] || [ -f $2/README* ];then
		echo "[$(date "+%H:%M:%S")] Package $2 is detected!"
		case $2 in
		OpenClash)
			mv -f ./$2/luci-app-openclash ./package/lean
		;;
		openwrt-OpenAppFilter)
			mv -f ./$2 ./package/lean
		;;
		*)
			mv -f ./$2 ./package/lean
		esac
		rm -rf ./$2 > /dev/null 2>&1
		break
	else
		[ $Retry_Times -lt 1 ] && echo "[$(date "+%H:%M:%S")] Skip check out package $1 ..." && break
		echo "[$(date "+%H:%M:%S")] [$Retry_Times]Checkout failed,retry in 3s ..."
		Retry_Times=$(($Retry_Times - 1))
		rm -rf ./$2 > /dev/null 2>&1
		sleep 3
	fi
done
}

mv2() {
if [ -f $GITHUB_WORKSPACE/Customize/$1 ];then
	echo "[$(date "+%H:%M:%S")] Custom File [$1] is detected!"
	if [ -z $2 ];then
		Patch_Dir=$GITHUB_WORKSPACE/openwrt
	else
		Patch_Dir=$GITHUB_WORKSPACE/openwrt/$2
	fi
	[ ! -d $Patch_Dir ] && mkdir -p $Patch_Dir
	if [ -z $3 ];then
		[ -f $Patch_Dir/$1 ] && rm -f $Patch_Dir/$1 > /dev/null 2>&1
		mv -f $GITHUB_WORKSPACE/Customize/$1 $Patch_Dir/$1
	else
		[ -f $Patch_Dir/$1 ] && rm -f $Patch_Dir/$3 > /dev/null 2>&1
		mv -f $GITHUB_WORKSPACE/Customize/$1 $Patch_Dir/$3
	fi
else
	echo "[$(date "+%H:%M:%S")] Custom File [$1] is not detected!"
fi
}

Diy-Part1() {
[ -f feeds.conf.default ] && sed -i "s/#src-git helloworld/src-git helloworld/g" feeds.conf.default
[ ! -d ./package/lean ] && mkdir ./package/lean

# mv2 feeds.conf.default
mv2 mac80211.sh package/kernel/mac80211/files/lib/wifi
mv2 system package/base-files/files/etc/config
mv2 AutoUpdate.sh package/base-files/files/bin
mv2 banner package/base-files/files/etc
mv2 mt76.mk package/kernel/mt76 Makefile

# ExtraPackages svn mac80211 https://github.com/openwrt/openwrt/trunk/package/kernel
# rm -rf package/kernel/mac80211 && mv -f package/lean/mac80211 package/kernel
ExtraPackages svn dnsmasq https://github.com/openwrt/openwrt/trunk/package/network/services
rm -rf package/network/services/dnsmasq && mv -f package/lean/dnsmasq package/network/services
ExtraPackages svn hostapd https://github.com/openwrt/openwrt/trunk/package/network/services
rm -rf package/network/services/hostapd && mv -f package/lean/hostapd package/network/services
ExtraPackages svn dropbear https://github.com/openwrt/openwrt/trunk/package/network/services
rm -rf package/network/services/dropbear && mv -f package/lean/dropbear package/network/services

ExtraPackages git luci-app-autoupdate https://github.com/Hyy2001X main
ExtraPackages git luci-theme-argon https://github.com/jerrykuku 18.06
ExtraPackages git luci-app-argon-config https://github.com/jerrykuku master
ExtraPackages git luci-app-adguardhome https://github.com/Hyy2001X master
ExtraPackages svn luci-app-smartdns https://github.com/project-openwrt/openwrt/trunk/package/ntlf9t
ExtraPackages svn smartdns https://github.com/project-openwrt/openwrt/trunk/package/ntlf9t
ExtraPackages git OpenClash https://github.com/vernesong master
ExtraPackages git luci-app-serverchan https://github.com/tty228 master
# ExtraPackages git OpenAppFilter https://github.com/destan19 master
ExtraPackages svn luci-app-socat https://github.com/xiaorouji/openwrt-package/trunk/lienol
# ExtraPackages git openwrt-upx https://github.com/Hyy2001X master
# ExtraPackages svn luci-app-mentohust https://github.com/project-openwrt/openwrt/trunk/package/ctcgfw
# ExtraPackages svn mentohust https://github.com/project-openwrt/openwrt/trunk/package/ctcgfw
#ExtraPackages svn luci-theme-opentomato https://github.com/kenzok8/openwrt-packages/trunk
#ExtraPackages svn luci-theme-opentomcat https://github.com/kenzok8/openwrt-packages/trunk
# ExtraPackages svn luci-app-adguardhome https://github.com/Lienol/openwrt/trunk/package/diy
# ExtraPackages git luci-app-adguardhome https://github.com/rufengsuixing master
ExtraPackages git openwrt-OpenAppFilter https://github.com/Lienol master
}

Diy-Part2() {
GET_TARGET_INFO
mv2 mwan3 package/feeds/packages/mwan3/files/etc/config
echo "Author: $Author"
echo "Lede Version: $Openwrt_Version"
echo "AutoUpdate Version: $AutoUpdate_Version"
echo "Router: $TARGET_PROFILE"
sed -i "s?$Lede_Version?$Lede_Version Compiled by $Author [$Compile_Date]?g" $Default_File
echo "$Openwrt_Version" > ./package/base-files/files/etc/openwrt_info
sed -i "s?Openwrt?Openwrt $Openwrt_Version / AutoUpdate $AutoUpdate_Version?g" ./package/base-files/files/etc/banner
}

Diy-Part3() {
GET_TARGET_INFO
Default_Firmware=openwrt-$TARGET_BOARD-$TARGET_SUBTARGET-$TARGET_PROFILE-squashfs-sysupgrade.bin
AutoBuild_Firmware=AutoBuild-$TARGET_PROFILE-Lede-${Openwrt_Version}.bin
AutoBuild_Detail=AutoBuild-$TARGET_PROFILE-Lede-${Openwrt_Version}.detail
mkdir -p ./bin/Firmware
echo "Firmware: $AutoBuild_Firmware"
mv ./bin/targets/$TARGET_BOARD/$TARGET_SUBTARGET/$Default_Firmware ./bin/Firmware/$AutoBuild_Firmware
echo "[$(date "+%H:%M:%S")] Calculating MD5 and SHA256 ..."
Firmware_MD5=`md5sum ./bin/Firmware/$AutoBuild_Firmware | cut -d ' ' -f1`
Firmware_SHA256=`sha256sum ./bin/Firmware/$AutoBuild_Firmware | cut -d ' ' -f1`
echo -e "MD5: $Firmware_MD5\nSHA256: $Firmware_SHA256"
echo "编译日期:$Compile_Time" > ./bin/Firmware/$AutoBuild_Detail
echo -e "\nMD5:$Firmware_MD5\nSHA256:$Firmware_SHA256" >> ./bin/Firmware/$AutoBuild_Detail
}
