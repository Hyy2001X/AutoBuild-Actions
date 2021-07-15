#!/bin/bash
# AutoBuild Module by Hyy2001 <https://github.com/Hyy2001X/AutoBuild-Actions>
# AutoBuild DiyScript

Diy_Core() {
	Author="Liyue Management Group"
	Short_Firmware_Date=true
	Default_LAN_IP=false

	INCLUDE_AutoBuild_Features=true
	INCLUDE_DRM_I915=true
	INCLUDE_Argon=true
	INCLUDE_Obsolete_PKG_Compatible=false
}

Firmware-Diy() {
	case "${TARGET_PROFILE}" in
	d-team_newifi-d2)
		Copy CustomFiles/mac80211.sh package/kernel/mac80211/files/lib/wifi
		Copy CustomFiles/system_${TARGET_PROFILE} package/base-files/files/etc/config system
	;;
	*)
		:
	esac
}
