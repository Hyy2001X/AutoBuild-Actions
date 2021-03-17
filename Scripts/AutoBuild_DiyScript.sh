#!/bin/bash
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001
# AutoBuild DiyScript

Diy_Core() {
	Author=Hyy2001
	Default_Device=

	INCLUDE_AutoUpdate=true
	INCLUDE_AutoBuild_Tools=true
	INCLUDE_mt7621_OC1000MHz=true
	INCLUDE_DRM_I915=true

	INCLUDE_SSR_Plus=true
	INCLUDE_Passwall=true
	INCLUDE_HelloWorld=false
	INCLUDE_Bypass=false
	INCLUDE_OpenClash=true
	INCLUDE_OAF=false
	INCLUDE_Argon=true
}

Diy-Part1() {
	Diy_Part1_Base

	Replace_File Customize/mac80211.sh package/kernel/mac80211/files/lib/wifi
	Replace_File Customize/coremark.sh package/lean/coremark
	Replace_File Customize/cpuinfo_x86 package/lean/autocore/files/x86/sbin cpuinfo
	Update_Makefile xray-core package/lean/helloworld/xray-core
	Update_Makefile exfat package/kernel/exfat

	ExtraPackages git other luci-app-argon-config https://github.com/jerrykuku
	ExtraPackages git other luci-app-adguardhome https://github.com/Hyy2001X
	ExtraPackages git other luci-app-shutdown https://github.com/Hyy2001X
	ExtraPackages svn other luci-app-smartdns https://github.com/immortalwrt/immortalwrt/trunk/package/ntlf9t
	ExtraPackages git other luci-app-serverchan https://github.com/tty228
	ExtraPackages svn other luci-app-socat https://github.com/Lienol/openwrt-package/trunk
	ExtraPackages svn other luci-app-usb3disable https://github.com/immortalwrt/immortalwrt/trunk/package/ctcgfw
	ExtraPackages svn lean luci-app-kodexplorer https://github.com/immortalwrt/immortalwrt/trunk/package/lean
	ExtraPackages svn other luci-app-filebrowser https://github.com/immortalwrt/immortalwrt/trunk/package/ctcgfw
	ExtraPackages svn other filebrowser https://github.com/immortalwrt/immortalwrt/trunk/package/ctcgfw
	ExtraPackages svn lean luci-app-eqos https://github.com/immortalwrt/immortalwrt/trunk/package/ntlf9t
	ExtraPackages git other luci-app-bearDropper https://github.com/NateLol
	ExtraPackages git other luci-app-onliner https://github.com/rufengsuixing
}

Diy-Part2() {
	Diy_Part2_Base
	ExtraPackages svn other/../../feeds/packages/admin netdata https://github.com/openwrt/packages/trunk/admin
}

Diy-Part3() {
	Diy_Part3_Base
}
