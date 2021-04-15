#!/bin/bash
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001
# AutoBuild DiyScript

Diy_Core() {
	Author=Hapi
	Default_Device=d-team_newifi-d2

	INCLUDE_AutoUpdate=true
	INCLUDE_AutoBuild_Tools=true
	INCLUDE_DRM_I915=true
	INCLUDE_Theme_Argon=true
	INCLUDE_Obsolete_PKG_Compatible=false
}

Firmware-Diy() {
	Update_Makefile exfat package/kernel/exfat

        sed -i 's/192.168.1.1/192.168.2.1/g' package/base-files/files/bin/config_generate
   
	ExtraPackages svn ../feeds/packages/admin netdata https://github.com/openwrt/packages/trunk/admin

	case ${TARGET_PROFILE} in
	d-team_newifi-d2)
		Replace_File CustomFiles/mac80211.sh package/kernel/mac80211/files/lib/wifi
		Replace_File CustomFiles/system_d-team_newifi-d2 package/base-files/files/etc/config system
		Replace_File CustomFiles/Patches/102-mt7621-fix-cpu-clk-add-clkdev.patch target/linux/ramips/patches-5.4
	;;
	esac
}
