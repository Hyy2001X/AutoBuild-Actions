#!/bin/bash
# https://github.com/konbar/AutoBuild-Actions
# AutoBuild Module by konbar
# AutoBuild Actions

Diy_Core() {
Author=konbar

Default_File=./package/lean/default-settings/files/zzz-default-settings
FIRMWARE_SUFFIX=squashfs-sysupgrade.bin
Lede_Version=`egrep -o "R[0-9]+\.[0-9]+\.[0-9]+" $Default_File`
Compile_Date=`date +'%Y/%m/%d'`
Compile_Time=`date +'%Y-%m-%d %H:%M:%S'`
TARGET_PROFILE=`grep '^CONFIG_TARGET.*DEVICE.*=y' .config | sed -r 's/.*DEVICE_(.*)=y/\1/'`
}

GET_TARGET_INFO() {
TARGET_BOARD=`awk -F'[="]+' '/TARGET_BOARD/{print $2}' .config`
TARGET_SUBTARGET=`awk -F'[="]+' '/TARGET_SUBTARGET/{print $2}' .config`
}

ExtraPackages() {
[ -d ./package/lean/$2 ] && rm -rf ./package/lean/$2
[ -d ./$2 ] && rm -rf ./$2
while [ ! -f $2/Makefile ]
do
	echo "[$(date "+%H:%M:%S")] Checking out $2 from $3 ..."
	if [ $1 == git ];then
		git clone -b $4 $3/$2 $2 > /dev/null 2>&1
	else
		svn checkout $3/$2 $2 > /dev/null 2>&1
	fi
	if [ -f $2/Makefile ] || [ -f $2/README* ];then
		echo "[$(date "+%H:%M:%S")] Package $2 detected!"
		if [ $2 == OpenClash ];then
			mv $2/luci-app-openclash ./package/lean
		else
			mv $2 ./package/lean
		fi
		rm -rf ./$2 > /dev/null 2>&1
		break
	else
		echo "[$(date "+%H:%M:%S")] Checkout failed,retry in 3s."
		rm -rf ./$2 > /dev/null 2>&1
		sleep 3
	fi
done
}

Diy-Part1() {
sed -i "s/#src-git helloworld/src-git helloworld/g" feeds.conf.default
[ ! -d ./package/lean ] && mkdir ./package/lean
ExtraPackages git luci-theme-argon https://github.com/jerrykuku 18.06
ExtraPackages svn luci-app-adguardhome https://github.com/Lienol/openwrt/trunk/package/diy
ExtraPackages svn luci-app-smartdns https://github.com/project-openwrt/openwrt/trunk/package/ntlf9t
ExtraPackages svn smartdns https://github.com/project-openwrt/openwrt/trunk/package/ntlf9t
ExtraPackages git OpenClash https://github.com/vernesong master
}

Diy-Part2() {
echo "Current Openwrt version: $Lede_Version-`date +%Y%m%d`"
echo "Current Device: $TARGET_PROFILE"
sed -i "s?$Lede_Version?$Lede_Version Compiled by $Author [$Compile_Date]?g" $Default_File
echo "$Lede_Version-`date +%Y%m%d`" > ./package/base-files/files/etc/openwrt_date
}

Diy-Part3() {
GET_TARGET_INFO
Default_Firmware=openwrt-$TARGET_BOARD-$TARGET_SUBTARGET-$TARGET_PROFILE-$FIRMWARE_SUFFIX
AutoBuild_Firmware=AutoBuild-$TARGET_PROFILE-Lede-$Lede_Version`(date +-%Y%m%d.bin)`
AutoBuild_Detail=AutoBuild-$TARGET_PROFILE-Lede-$Lede_Version`(date +-%Y%m%d.detail)`
mkdir -p ./bin/Firmware
echo "[$(date "+%H:%M:%S")] Moving $Default_Firmware to /bin/Firmware/$AutoBuild_Firmware ..."
mv ./bin/targets/$TARGET_BOARD/$TARGET_SUBTARGET/$Default_Firmware ./bin/Firmware/$AutoBuild_Firmware
cd ./bin/Firmware
echo "[$(date "+%H:%M:%S")] Calculating MD5 and SHA256 ..."
Firmware_MD5=`md5sum $AutoBuild_Firmware | cut -d ' ' -f1`
Firmware_SHA256=`sha256sum $AutoBuild_Firmware | cut -d ' ' -f1`
echo -e "编译日期:$Compile_Time\n" > ./$AutoBuild_Detail
echo -e "MD5:$Firmware_MD5\nSHA256:$Firmware_SHA256" >> ./$AutoBuild_Detail
cd ../..
}
