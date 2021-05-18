#!/bin/bash
# https://github.com/Hyy2001X/AutoBuild-Actions
# AutoBuild Module by Hyy2001
# AutoUpdate for Openwrt

Version=V5.7.6

Shell_Helper() {
cat <<EOF

使用方法:	$0 [<更新参数] [-n] [-f] [-u] [-p] [-np] [-fp]
		$0 [<设置参数>...] [-c] [-b] <额外参数>
		$0 [<其他>...] [-x] [-xp] [-l] [-lp] [-d] [-h]
		$0 [<更新参数>...] [<测试模式>...] 

更新参数:
	-n		更新固件 [不保留配置]
	-np		更新固件 [不保留配置] (强制镜像加速)
	-f		强制更新固件,即跳过版本号验证,自动下载以及安装必要软件包 [保留配置]
	-u		适用于定时更新 LUCI 的参数 [保留配置]

设置参数:
	-c		[额外参数:<Github 地址>] 更换 Github 地址
	-b		[额外参数:<引导方式 UEFI/Legacy>] 指定 x86 设备下载使用 UEFI/Legacy 引导的固件 (危险)

更新脚本:
	-x		更新 AutoUpdate.sh 脚本
	-xp		更新 AutoUpdate.sh 脚本 (强制镜像加速)

测试模式:
	-t		测试模式 (仅运行流程,不更新固件)

其他:
	-l		列出系统信息
	-d		清理固件下载缓存
	-h		打印帮助信息

EOF
exit 0
}

List_Info() {
cat <<EOF

AutoUpdate 版本:	${Version}
/overlay 可用:		${Overlay_Available}
/tmp 可用:		${TMP_Available}M
固件下载位置:		${Download_Path}
当前设备:		${CURRENT_Device}
默认设备:		${DEFAULT_Device}
当前固件版本:		${CURRENT_Version}
固件名称:		AutoBuild-${CURRENT_Device}-${CURRENT_Version}${Firmware_SFX}
Github:			${Github}
Github Raw:		${Github_Raw}
解析 API:		${Github_Tags}
固件下载地址:		${Github_Release}
作者/仓库:		${Author}
固件格式:		${Firmware_SFX}
EOF
	[[ "${DEFAULT_Device}" == x86_64 ]] && {
		echo "EFI 引导:		${EFI_Mode}"
		echo "固件压缩:		${Compressed_Firmware}"
	}
	exit 0
}

Install_Pkg() {
	export PKG_NAME=$1
	if [[ ! "$(cat ${Download_Path}/Installed_PKG_List)" =~ "${PKG_NAME}" ]];then
		[[ "${Force_Update}" == 1 ]] || [[ "${AutoUpdate_Mode}" == 1 ]] && {
			export Choose=Y
		} || {
			TIME && read -p "未安装[${PKG_NAME}],是否执行安装?[Y/n]:" Choose
		}
		if [[ "${Choose}" == Y ]] || [[ "${Choose}" == y ]];then
			TIME "开始安装[${PKG_NAME}],请耐心等待...\n"
			opkg update > /dev/null 2>&1
			opkg install ${PKG_NAME}
			[[ ! $? -ne 0 ]] && {
				TIME "[${PKG_NAME}] 安装成功!"
			} || {
				TIME "[${PKG_NAME}] 安装失败,请尝试手动安装!"
				exit 1
			}
		else
			TIME "用户已取消安装,即将退出更新脚本..."
			sleep 2
			exit 0
		fi
	fi
}

TIME() {
	[ ! -f /tmp/AutoUpdate.log ] && touch /tmp/AutoUpdate.log
	[[ -z "$1" ]] && {
		echo -ne "\n\e[36m[$(date "+%H:%M:%S")]\e[0m "
	} || {
	case $1 in
		r) export Color="\e[31m";;
		g) export Color="\e[32m";;
		b) export Color="\e[34m";;
		y) export Color="\e[33m";;
	esac
		[[ $# -lt 2 ]] && {
			echo -e "\n\e[36m[$(date "+%H:%M:%S")]\e[0m ${1}"
			echo "[$(date "+%H:%M:%S")] ${1}" >> /tmp/AutoUpdate.log
		} || {
			echo -e "\n\e[36m[$(date "+%H:%M:%S")]\e[0m ${Color}${2}\e[0m"
			echo "[$(date "+%H:%M:%S")] ${2}" >> /tmp/AutoUpdate.log
		}
	}
}

[ -f /etc/openwrt_info ] && source /etc/openwrt_info || {
	TIME r "未检测到 /etc/openwrt/info,无法运行更新程序!"
	exit 1
}

export Input_Option=$1
export Input_Other=$2
export Input_All="$*"
export Download_Path="/tmp/Downloads"
export Github_Release="${Github}/releases/download/AutoUpdate"
export Author="${Github##*com/}"
export CLOUD_Script="Hyy2001X/AutoBuild-Actions/master/Scripts/AutoUpdate.sh"
export Github_Tags="https://api.github.com/repos/${Author}/releases/latest"
export Github_Raw="https://raw.githubusercontent.com"
export _PROXY_Release="https://download.fastgit.org"
export TMP_Available="$(df -m | grep "/tmp" | awk '{print $4}' | awk 'NR==1' | awk -F. '{print $1}')"
export Overlay_Available="$(df -h | grep ":/overlay" | awk '{print $4}' | awk 'NR==1')"
export Retry_Times=5
[[ -z "${CURRENT_Version}" ]] && export CURRENT_Version="$(egrep -o "R[0-9].+-[0-9]+" /etc/banner)" || export CURRENT_Version="$(egrep -o "R[0-9].+-[0-9]+" /rom/etc/openwrt_info)"
[ ! -d "${Download_Path}" ] && mkdir -p ${Download_Path}
opkg list | awk '{print $1}' > ${Download_Path}/Installed_PKG_List
case ${DEFAULT_Device} in
x86_64)
	[[ -z "${Firmware_Type}" ]] && Firmware_Type=img
	[[ "${Firmware_Type}" == img.gz ]] && {
		export Compressed_Firmware=1
	} || export Compressed_Firmware=0
	[ -f /etc/openwrt_boot ] && {
		export BOOT_Type="-$(cat /etc/openwrt_boot)"
	} || {
		[ -d /sys/firmware/efi ] && {
			export BOOT_Type="-UEFI"
		} || export BOOT_Type="-Legacy"
	}
	case ${BOOT_Type} in
	-Legacy)
		export EFI_Mode=0
	;;
	-UEFI)
		export EFI_Mode=1
	;;
	esac
	export Firmware_SFX="${BOOT_Type}.${Firmware_Type}"
	export Detail_SFX="${BOOT_Type}.detail"
	export CURRENT_Device=x86_64
	export Space_Min=480
;;
*)
	export CURRENT_Device="$(jsonfilter -e '@.model.id' < /etc/board.json | tr ',' '_')"
	export Firmware_SFX=".${Firmware_Type}"
	[[ -z ${Firmware_SFX} ]] && export Firmware_SFX=".bin"
	export Detail_SFX=.detail
	export Space_Min=0
esac
cd /etc
clear && echo "Openwrt-AutoUpdate Script ${Version}"
if [[ -z "${Input_Option}" ]];then
	export Upgrade_Options="-q"
	TIME g "执行: 保留配置更新固件"
else
	[[ "${Input_All}" =~ p ]] && {
		export PROXY_Release="${_PROXY_Release}"
		export PROXY_Mode=1
		export Github_Raw="https://raw.fastgit.org"
		export PROXY_ECHO="[FastGit] "
	} || {
		export PROXY_ECHO=""
	}
	case ${Input_Option} in
	-t | -n | -f | -u | -p | -np | -pn | -fp | -pf | -up | -pu)
		case ${Input_Option} in
		-t)
			Input_Other="-t"
		;;
		-n | -np | -pn)
			TIME g "${PROXY_ECHO}执行: 更新固件(不保留配置)"
			export Upgrade_Options="-n"
		;;
		-f | -pf | -fp)
			export Force_Update=1
			export Upgrade_Options="-q"
			TIME g "${PROXY_ECHO}执行: 强制更新固件(保留配置)"
		;;
		-u | -pu | -up)
			export AutoUpdate_Mode=1
			export Upgrade_Options="-q"
		;;
		-p | -pq | -qp)
			export Upgrade_Options="-q"
			TIME g "${PROXY_ECHO}执行: 保留配置更新固件"
		;;
		esac
	;;
	-c)
		if [[ -n "${Input_Other}" ]] && [[ ! "${Input_Other}" == "-t" ]];then
			[[ ! "${Input_Other}" =~ "https://github.com/" ]] && {
				TIME r "INPUT: ${Input_Other}"
				TIME r "错误的 Github 地址,请重新输入!"
				TIME b "正确示例: https://github.com/Hyy2001X/AutoBuild-Actions"
				exit 1
			}
			Github_uci=$(uci get autoupdate.@login[0].github 2>/dev/null)
			[[ -n "${Github_uci}" ]] && [[ "${Github_uci}" != "${Input_Other}" ]] && {
				uci set autoupdate.@login[0].github=${Input_Other}
				uci commit autoupdate
				TIME y "UCI 设置已更新!"
			}
			[[ "${Github}" != "${Input_Other}" ]] && {
				sed -i "s?${Github}?${Input_Other}?g" /etc/openwrt_info
				TIME y "Github 地址已更换为: ${Input_Other}"
				unset Input_Other
				exit 0
			} || {
				TIME r "INPUT: ${Input_Other}"
				TIME r "输入的 Github 地址相同,无需修改!"
				exit 1
			}
		else
			Shell_Helper
		fi
	;;
	-l | -lp | -pl)
		List_Info
	;;
	-d)
		rm -f ${Download_Path}/*
		TIME y "固件下载缓存清理完成!"
		exit 0
	;;
	-h)
		Shell_Helper
	;;
	-b)
		if [[ -n "${Input_Other}" ]];then
			case "${Input_Other}" in
			UEFI | Legacy)
				echo "${Input_Other}" > /etc/openwrt_boot
				sed -i '/openwrt_boot/d' /etc/sysupgrade.conf
				echo -e "\n/etc/openwrt_boot" >> /etc/sysupgrade.conf
				TIME y "固件引导方式已指定为: ${Input_Other}!"
				exit 0
			;;
			*)
				TIME r "错误的参数: [${Input_Other}],当前支持的选项: [UEFI/Legacy] !"
				exit 1
			;;
			esac
		else
			Shell_Helper
		fi
	;;
	-x | -xp | -px)
		export CLOUD_Script=${Github_Raw}/Hyy2001X/AutoBuild-Actions/master/Scripts/AutoUpdate.sh
		TIME "${PROXY_ECHO}开始更新 AutoUpdate 脚本,请耐心等待..."
		wget -q --tries 3 --timeout 5 ${CLOUD_Script} -O ${Download_Path}/AutoUpdate.sh
		if [[ $? == 0 ]];then
			rm /bin/AutoUpdate.sh
			mv -f ${Download_Path}/AutoUpdate.sh /bin
			chmod +x /bin/AutoUpdate.sh
			NEW_Version=$(egrep -o "V[0-9]+.[0-9].+" /bin/AutoUpdate.sh | awk 'NR==1')
			export Banner_Version=$(egrep -o "V[0-9]+.[0-9].+" /etc/banner)
			[[ -n "${Banner_Version}" ]] && sed -i "s?${Banner_Version}?${NEW_Version}?g" /etc/banner
			TIME "AutoUpdate.sh: [${Version}] > [${NEW_Version}]"
			TIME y "AutoUpdate 脚本更新成功!"
			exit 0
		else
			TIME r "AutoUpdate 脚本更新失败,请检查网络后重试!"
			exit 1
		fi	
	;;
	*)
		echo -e "\nERROR INPUT: [$*]"
		Shell_Helper
	;;
	esac
fi
[[ "${Input_All}" =~ "t" ]] && TIME b "测试模式"
if [[ -z "${PROXY_Release}" ]];then
	if [[ "$(cat ${Download_Path}/Installed_PKG_List)" =~ curl ]];then
		export Google_Check=$(curl -I -s --connect-timeout 3 google.com -w %{http_code} | tail -n1)
		[[ ! "$Google_Check" == 301 ]] && {
			TIME r "Google 连接失败,尝试使用 [FastGit] 镜像加速!"
			export PROXY_Release="${_PROXY_Release}"
		}
	else
		TIME r "无法确定网络环境,默认开启 [FastGit] 镜像加速!"
		export PROXY_Release="${_PROXY_Release}"
	fi
fi
[[ "${TMP_Available}" -lt "${Space_Min}" ]] && {
	TIME r "/tmp 空间不足: [${Space_Min}M],无法执行更新!"
	exit 1
}
Install_Pkg wget
if [[ -z "${CURRENT_Version}" ]];then
	TIME r "警告: 当前固件版本获取失败!"
	export CURRENT_Version=Unknown
fi
if [[ -z "${CURRENT_Device}" ]];then
	[[ -n "$DEFAULT_Device" ]] && {
		TIME r "警告: 当前设备名称获取失败,使用预设名称: [$DEFAULT_Device]"
		export CURRENT_Device="${DEFAULT_Device}"
	} || {
		TIME r "未检测到设备名称,无法执行更新!"
		exit 1
	}
fi
TIME "正在检查版本更新..."
wget -q --timeout 5 ${Github_Tags} -O - > ${Download_Path}/Github_Tags
[[ ! $? == 0 ]] && {
	TIME r "检查更新失败,请稍后重试!"
	exit 1
}
export CLOUD_Firmware=$(egrep -o "AutoBuild-${CURRENT_Device}-R[0-9].+-[0-9]+${Firmware_SFX}" ${Download_Path}/Github_Tags | awk 'END {print}')
export CLOUD_Version=$(echo ${CLOUD_Firmware} | egrep -o "R[0-9].+-[0-9]+")
[[ -z "${CLOUD_Version}" ]] && {
	TIME r "云端固件信息获取失败!"
	exit 1
}
export Firmware_Name="$(echo ${CLOUD_Firmware} | egrep -o "AutoBuild-${CURRENT_Device}-R[0-9].+-[0-9]+")"
export Firmware="${CLOUD_Firmware}"
export Firmware_Detail="${Firmware_Name}${Detail_SFX}"
let X="$(grep -n "${Firmware}" ${Download_Path}/Github_Tags | tail -1 | cut -d : -f 1)-4"
let CLOUD_Firmware_Size="$(sed -n "${X}p" ${Download_Path}/Github_Tags | egrep -o "[0-9]+" | awk '{print ($1)/1048576}' | awk -F. '{print $1}')+1"
echo -e "\n固件作者: ${Author%/*}"
echo "设备名称: $(uname -n) / ${CURRENT_Device}"
echo "固件格式: ${Firmware_SFX}"
echo -e "\n当前固件版本: ${CURRENT_Version}"
echo "云端固件版本: ${CLOUD_Version}"
echo "可用空间: ${TMP_Available}M"
echo "固件大小: ${CLOUD_Firmware_Size}M"
if [[ ! "${Force_Update}" == 1 ]];then
	[[ "${TMP_Available}" -lt "${CLOUD_Firmware_Size}" ]] && {
		TIME r "/tmp 空间不足: [${CLOUD_Firmware_Size}M],无法执行更新!"
		exit
	}
	if [[ "${CURRENT_Version}" == "${CLOUD_Version}" ]];then
		[[ "${AutoUpdate_Mode}" == 1 ]] && exit 0
		TIME && read -p "已是最新版本,是否强制更新固件?[Y/n]:" Choose
		[[ "${Choose}" == Y ]] || [[ "${Choose}" == y ]] && {
			TIME g "开始强制更新固件..."
		} || {
			TIME y "已取消强制更新,退出更新程序..."
			sleep 1
			exit 0
		}
	fi
fi
[[ -n "${PROXY_Release}" ]] && export Github_Release="${PROXY_Release}/${Author}/releases/download/AutoUpdate"
echo -e "\n云端固件名称: ${Firmware}"
echo "固件下载地址: ${Github_Release}"
rm -f ${Download_Path}/AutoBuild-*
TIME "正在下载固件和云端固件信息,请耐心等待..."
cd ${Download_Path}
while [ "${Retry_Times}" -ge 0 ];
do
	if [[ "${Retry_Times}" == 4 ]];then
		[[ -z "${PROXY_Release}" ]] && {
			TIME "正在尝试使用 [FastGit] 镜像加速下载..."
			export Github_Release="${_PROXY_Release}/${Author}/releases/download/AutoUpdate"
		}
	fi
	if [[ "${PROXY_Mode}" != 1 ]];then
		[[ "${Retry_Times}" == 2 ]] && {
			export Github_Release="https://github.com/${Author}/releases/download/AutoUpdate"
		}
	fi
	if [[ "${Retry_Times}" == 0 ]];then
		TIME r "固件下载失败,请检查网络后重试!"
		exit 1
	else
		[[ "${A}" != 1 ]] && wget -q --tries 2 --timeout 5 "${Github_Release}/${Firmware}" -O ${Firmware}
		[[ $? == 0 ]] && export A=1 && TIME y "固件下载成功!"
		[[ "${B}" != 1 ]] && wget -q --tries 1 --timeout 5 ${Github_Release}/${Firmware_Detail} -O ${Firmware_Detail}
		[[ $? == 0 ]] && export B=1 && TIME y "云端固件信息下载成功!"
		let C=${A}+${B}
		[[ "${C}" == 2 ]] && break
	fi
	export Retry_Times=$((${Retry_Times} - 1))
	TIME r "下载失败,剩余尝试次数: [${Retry_Times}]"
	sleep 1
done
unset C
CLOUD_MD5=$(awk -F '[ :]' '/MD5/ {print $2;exit}' ${Firmware_Detail})
CURRENT_MD5=$(md5sum ${Firmware} | cut -d ' ' -f1)
[[ "${CLOUD_MD5}" != "${CURRENT_MD5}" ]] && {
	echo -e "\n本地固件MD5: ${CURRENT_MD5}"
	echo "云端固件MD5: ${CLOUD_MD5}"
	TIME r "MD5 对比失败,请重新尝试执行更新!"
	exit 1
}
if [[ "${Compressed_Firmware}" == 1 ]];then
	Install_Pkg gzip
	gzip -dk ${Firmware} > /dev/null 2>&1
	export Firmware="${Firmware_Name}${BOOT_Type}.img"
	[[ $? == 0 ]] && {
		TIME y "固件解压成功,固件名称: ${Firmware}"
	} || {
		TIME r "固件解压失败,请检查系统可用空间!"
		exit 1
	}
fi
[[ "${Input_Other}" == "-t" ]] && {
	TIME b "测试模式运行完毕!"
	exit 0
}
sleep 3
TIME g "正在更新固件,更新期间请耐心等待..."
sleep 1
sysupgrade ${Upgrade_Options} ${Firmware}
[[ $? -ne 0 ]] && {
	TIME r "固件刷写失败,请尝试手动更新固件!"
	exit 1
}
