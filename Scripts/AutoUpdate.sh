#!/bin/bash
# AutoBuild Module by Hyy2001 <https://github.com/Hyy2001X/AutoBuild-Actions>
# AutoUpdate for Openwrt
# Depends on: bash wget-ssl/wget/uclient-fetch curl x86:gzip openssl

TITLE() {
	clear && echo "Openwrt-AutoUpdate Script by Hyy2001 ${Version} [${DL}]"
}

SHELL_HELP() {
	TITLE
	cat <<EOF

使用方法:	$0 [<path=>] [-P] [-n] [-f] [-u]
		$0 [<更新脚本>] [-x/-x path=<>/-x url=<>]

更新固件:
	-n		更新固件 [不保留配置]
	-f		跳过版本号验证,并强制刷写固件 [保留配置]
	-u		适用于定时更新 LUCI 的参数 [保留配置]
	-F		强制刷写固件
	--skip		跳过固件 SHA256 比对校验 (危险)
	path=<Path>	更新固件 (保存固件到提供的绝对路径 <Path>)

更新脚本:
	-x			更新 AutoUpdate.sh 脚本
	-x path=<Path>		更新 AutoUpdate.sh 脚本 (保存脚本到提供的路径 <Path>)
	-x url=<URL>		更新 AutoUpdate.sh 脚本 (使用提供的地址 <URL> 更新脚本)

其他参数:
	-P,--proxy		优先开启镜像加速
	-C <Github URL>		更改 Github 地址为提供的 <Github URL>
	-B <UEFI | Legacy>	指定 x86_64 设备下载 <UEFI | Legacy> 引导的固件 (危险)
	-V < | cloud>		打印 <当前 | 云端> AutoUpdate.sh 版本号
	-E < | cloud | *>	打印 <当前 | 云端 | 指定版本> 版本的固件更新日志
	-H,--help		打印 AutoUpdate 帮助信息
	-L,--list		打印当前系统信息
	-Q < | cloud>		打印 <当前 | 云端> 固件版本
	--bak <Path> <Name>	备份当前系统配置文件到指定的 <Path> 路径及名称 <Name>
	--clean			清理 AutoUpdate 缓存
	--check			检查 AutoUpdate 依赖软件包
	--verbose		打印更详细的下载信息
	--var <Variable>	打印用户指定的变量 <Variable>
	--var-rm <Variable>	删除用户指定的变量 <Variable>
	--env < | 1 | 2>	打印 AutoUpdate 环境变量 <全部 | 变量名称 | 值>
	--log < | del>		<打印 | 删除> AutoUpdate 历史运行日志
	--log path=<Path>	更改 AutoUpdate 运行日志路径为提供的路径 <Path>
	--random <Number>	打印一个 <0-31> 位的随机数字与字母组合

EOF
	EXIT
}

SHOW_VARIABLE() {
	TITLE
	cat <<EOF

设备名称:		$(uname -n) / ${TARGET_PROFILE}
固件版本:		${CURRENT_Version}
固件作者:		${Author}
软件架构:		${TARGET_SUBTARGET}
作者仓库:		${Github}
OpenWrt 源码:		https://github.com/${Openwrt_Maintainer}/${OP_REPO_NAME}:${OP_BRANCH}	
Release API:		${Github_API}
固件格式-框架:		$(GET_VARIABLE AutoBuild_Firmware ${Default_Variable})
固件名称-框架:		$(GET_VARIABLE Egrep_Firmware ${Default_Variable})
固件格式:		${Firmware_Type}
Release URL:		${Github_Release_URL}
FastGit URL:		${Release_FastGit_URL}
Github Proxy URL:	${Release_Goproxy_URL}
固件保存位置:		${AutoUpdate_Path}
运行日志:		${AutoUpdate_Log_Path}/AutoUpdate.log
Downloader:		${Downloader}
EOF
	[[ ${TARGET_PROFILE} == x86_64 ]] && {
		echo "x86_64 引导模式:	${x86_64_Boot}"
	}
	EXIT 0
}

GET_PID() {
	local Result
	while [[ $1 ]];do
		Result=$(busybox ps | grep "$1" | grep -v "grep" | awk '{print $1}' | awk 'NR==1')
		[[ -n ${Result} ]] && echo ${Result}
	shift
	done
}

KILL_PID() {
	local Result
	Result=$(kill -9 $1)
}

UCI_GET() {
	local Result="$(uci get $1.@$2[0].$3 2>/dev/null)"
	[[ -n ${Result} ]] && echo "${Result}"
}

UCI_SET() {
	uci set $1.@$2[0].$3=$4 2>/dev/null
	uci commit $1
}

LIST_ENV() {
	local X
	cat /etc/AutoBuild/*_Variable | grep -v '#' | while read X;do
	[[ ${X} =~ "=" ]] && {
		case $1 in
		1 | 2)
			[[ -n $(echo ${X} | cut -d "=" -f1) ]] && echo ${X} | cut -d "=" -f$1
		;;
		0)
			echo ${X}
		;;
		esac
	}
	done
}

EXIT() {
	local RUN_TYPE
	LOGGER "Command :[${Run_Command}] Finished $1"
	exit 0
}

ECHO() {
	local Color
	[[ -z $1 ]] && {
		echo -ne "\n${Grey}[$(date "+%H:%M:%S")]${White} "
	} || {
	case $1 in
		r) Color="${Red}";;
		g) Color="${Green}";;
		b) Color="${Blue}";;
		y) Color="${Yellow}";;
		x) Color="${Grey}";;
	esac
		[[ $# -lt 2 ]] && {
			echo -e "\n${Grey}[$(date "+%H:%M:%S")]${White} $1"
			LOGGER $1
		} || {
			echo -e "\n${Grey}[$(date "+%H:%M:%S")]${White} ${Color}$2${White}"
			LOGGER $2
		}
	}
}

LOGGER() {
	[[ ! -d ${AutoUpdate_Log_Path} ]] && mkdir -p ${AutoUpdate_Log_Path}
	[[ ! -f ${AutoUpdate_Log_Path}/AutoUpdate.log ]] && touch ${AutoUpdate_Log_Path}/AutoUpdate.log
	echo "[$(date "+%Y-%m-%d-%H:%M:%S")] [$(GET_PID AutoUpdate.sh)] $*" >> ${AutoUpdate_Log_Path}/AutoUpdate.log
}

CHECK_PKG() {
	which $1 > /dev/null 2>&1
	[[ $? == 0 ]] && echo true || echo false
}

RANDOM() {
	local Result=$(openssl rand -base64 $1 | md5sum | cut -c 1-$1)
	[[ -n ${Result} ]] && echo ${Result}
	LOGGER "[RANDOM] $1-bit random-number : ${Result}"
}

GET_SHA256SUM() {
	[[ ! -f $1 && ! -s $1 ]] && {
		ECHO r "未检测到文件: [$1] 或该文件为空,无法计算 SHA256 值!"
		EXIT 1
	}
	local Result=$(sha256sum $1 | cut -c1-$2)
	[[ -n ${Result} ]] && echo ${Result}
	LOGGER "[GET_SHA256SUM] File [$1] Calculated result: ${Result}"
}

GET_VARIABLE() {
	[[ $# != 2 ]] && SHELL_HELP
	[[ ! -f $2 ]] && ECHO "未检测到定义文件: [$2] !" && EXIT 1
	local Result="$(grep "$1=" $2 | grep -v "#" | awk 'NR==1' | sed -r "s/$1=(.*)/\1/")"
	[[ -n ${Result} ]] && echo ${Result}
	LOGGER "[GET_VARIABLE] Get Variable: ${Result}"
}

LOAD_VARIABLE() {
	while [[ $1 ]];do
		[[ -f $1 ]] && {
			chmod 777 $1
			source $1
		}
		shift
	done
	[[ -z ${TARGET_PROFILE} ]] && TARGET_PROFILE="$(jsonfilter -e '@.model.id' < /etc/board.json | tr ',' '_')"
	[[ -z ${TARGET_PROFILE} ]] && ECHO r "获取设备名称失败,无法执行更新!" && EXIT 1
	[[ -z ${CURRENT_Version} ]] && CURRENT_Version=未知
	Github_Release_URL="${Github}/releases/download/AutoUpdate"
	FW_Author="${Github##*com/}"
	Github_API="https://api.github.com/repos/${FW_Author}/releases/latest"
	Release_URL="https://github.com/${FW_Author}/releases/download/AutoUpdate"
	Release_FastGit_URL="https://download.fastgit.org/${FW_Author}/releases/download/AutoUpdate"
	Release_Goproxy_URL="https://ghproxy.com/${Release_URL}"
	case ${TARGET_PROFILE} in
	x86_64)
		case ${Firmware_Type} in
		img.gz | img)
			[[ -z ${x86_64_Boot} ]] && {
				[ -d /sys/firmware/efi ] && {
					x86_64_Boot=UEFI
				} || x86_64_Boot=Legacy
			}
		;;
		*)
			ECHO r "[${TARGET_PROFILE}] 设备暂不支持当前固件格式!"
			EXIT 1
		;;
		esac
	;;
	*)
		[[ -z ${Firmware_Type} ]] && Firmware_Type=bin
	esac
}

EDIT_VARIABLE() {
	local Mode="$1"
	shift
	[[ ! -f $1 ]] && ECHO r "未检测到定义文件: [$1] !" && EXIT 1
	case "${Mode}" in
	edit)
    	[[ $# != 3 ]] && SHELL_HELP
		[[ -z $(GET_VARIABLE $2 $1) ]] && {
			LOGGER "[EDIT_VARIABLE] Appending [$2=$3] to $1 ..."
			echo -e "\n$2=$3" >> $1
		} || {
			sed -i "s?$(GET_VARIABLE $2 $1)?$3?g" $1
		}
	;;
	rm)
		[[ $# != 2 ]] && SHELL_HELP
		LOGGER "[EDIT_VARIABLE] Removing $2 from $1 ..."
		sed -i "/$2/d" $1
	;;
	esac
}

CHANGE_GITHUB() {
	[[ ! $1 =~ https://github.com/ ]] && {
		ECHO r "ERROR Github URL: $1"
		ECHO r "错误的 Github 地址,示例: https://github.com/Hyy2001X/AutoBuild-Actions"
		EXIT 1
	}
	UCI_Github_URL=$(UCI_GET autoupdate common github)
	[[ -n ${UCI_Github_URL} && ! ${UCI_Github_URL} == $1 ]] && {
		UCI_SET autoupdate common github $1
		ECHO y "UCI 设置已更新!"
	}
	[[ ! ${Github} == $1 ]] && {
		EDIT_VARIABLE edit ${Custom_Variable} Github $1
		ECHO y "Github 地址已修改为: $1"
	} || {
		ECHO y "当前输入的地址与原地址相同,无需修改!"
	}
	EXIT 0
}

CHANGE_BOOT() {
	[[ -z $1 ]] && SHELL_HELP
	case "$1" in
	UEFI | Legacy)
		EDIT_VARIABLE edit ${Custom_Variable} x86_64_Boot $1
		echo "ON" > /force_dump
		ECHO r "警告: 更换引导方式后更新固件后可能导致设备无法正常启动!"
		ECHO y "固件引导格式已指定为: [$1],AutoUpdate 将在下一次更新时执行强制刷写固件!"
		EXIT 0
	;;
	*)
		ECHO r "错误的参数: [$1],当前支持的选项: [UEFI/Legacy] !"
		EXIT 1
	;;
	esac
}

UPDATE_SCRIPT() {
	[[ $# != 2 ]] && SHELL_HELP
	ECHO b "脚本下载地址: $2"
	ECHO b "脚本保存路径: $1"
	[[ -f $1 ]] && {
		ECHO r "AutoUpdate 脚本保存路径有误,请重新输入!"
		EXIT 1
	}
	ECHO "开始更新 AutoUpdate 脚本,请耐心等待..."
	[[ ! -d $1 ]] && mkdir -p $1
	${Downloader} /tmp/AutoUpdate.sh $2
	if [[ $? == 0 && -s /tmp/AutoUpdate.sh ]];then
		mv -f /tmp/AutoUpdate.sh $1
		[[ ! $? == 0 ]] && ECHO r "AutoUpdate 脚本更新失败!" && EXIT 1
		chmod +x $1/AutoUpdate.sh
		NEW_Version=$(egrep -o "V[0-9].+" $1/AutoUpdate.sh | awk 'END{print}')
		Banner_Version=$(egrep -o "V[0-9]+.[0-9].+" /etc/banner)
		[[ -n ${Banner_Version} ]] && sed -i "s?${Banner_Version}?${NEW_Version}?g" /etc/banner
		ECHO y "[${Version}] > [${NEW_Version}] AutoUpdate 脚本更新成功!"
		EXIT 0
	else
		ECHO r "AutoUpdate 脚本更新失败,请检查网络后重试!"
		EXIT 1
	fi
}

CHECK_DEPENDS() {
	TITLE
	local PKG
	echo -e "\n软件包			检测结果"
	while [[ $1 ]];do
		if [[ $1 =~ : ]];then
			[[ $(echo $1 | cut -d ":" -f1) == ${TARGET_BOARD} ]] && {
				PKG="$(echo $1 | cut -d ":" -f2)"
				[[ $(echo ${PKG} | wc -c) -gt 8 ]] && Tab="		" || Tab="			"
				echo -e "${PKG}${Tab}$(CHECK_PKG ${PKG})"
				LOGGER "Checking ${PKG}... $(CHECK_PKG ${PKG})"
			}
		else
			[[ $(echo $1 | wc -c) -gt 8 ]] && Tab="		" || Tab="			"
			echo -e "$1${Tab}$(CHECK_PKG $1)"
			LOGGER "Checking $1... $(CHECK_PKG $1)"
		fi
		shift
	done
	ECHO y "AutoUpdate 依赖检测结束,若某项检测结果为 [false],请尝试手动安装!"
	EXIT
}

GET_FW_LOG() {
	local Update_Log
	case "$1" in
	local)
		FW_Version="${CURRENT_Version}"
	;;
	cloud)
		[[ -z ${CLOUD_Firmware_Version} ]] && GET_CLOUD_VERSION
		FW_Version="${CLOUD_Firmware_Version}"
	;;
	-v)
		shift
		FW_Version="$1"
	;;
	esac
	${Downloader} ${AutoUpdate_Path}/Update_Logs.json ${Release_URL}/Update_Logs.json
	[[ $? == 0 ]] && {
		Update_Log=$(jsonfilter -e '@["'"""${TARGET_PROFILE}"""'"]["'"""${FW_Version}"""'"]' < ${AutoUpdate_Path}/Update_Logs.json)
		rm -f ${AutoUpdate_Path}/Update_Logs.json
	} || return
	[[ -z ${Update_Log} ]] && return
	echo -e "\n${Grey}${FW_Version} for ${TARGET_PROFILE} 更新日志:"
	echo -e "\n${Green}${Update_Log}${White}"
}

GET_CLOUD_INFO() {
	[[ -f ${AutoUpdate_Path}/Github_Tags ]] && rm -f ${AutoUpdate_Path}/Github_Tags
	${Downloader} ${AutoUpdate_Path}/Github_Tags ${Github_API}
	[[ $? != 0 || ! -s ${AutoUpdate_Path}/Github_Tags ]] && {
		echo 0
	} || echo 1
}

GET_CLOUD_FW() {
	local X
	[[ $(GET_CLOUD_INFO) == 0 ]] && {
		ECHO r "检查更新失败,请稍后重试!"
		EXIT 1
	}
	eval X=$(GET_VARIABLE Egrep_Firmware ${Default_Variable})
	FW_Name=$(egrep -o "${X}" ${AutoUpdate_Path}/Github_Tags | awk 'END {print}')
	[[ -z ${FW_Name} ]] && ECHO "云端固件名称获取失败!" && EXIT 1
}

GET_CLOUD_VERSION() {
	GET_CLOUD_FW
	CLOUD_Firmware_Version=$(echo "${FW_Name}" | egrep -o "R[0-9].*202[1-2][0-9]+")
	[[ -z ${CLOUD_Firmware_Version} ]] && ECHO "云端固件版本获取失败!" && EXIT 1
}

CHECK_UPDATES() {
	ECHO "正在获取版本更新 ..."
	GET_CLOUD_VERSION
	[[ ${CLOUD_Firmware_Version} == ${CURRENT_Version} ]] && {
		CURRENT_Type="${Yellow} [已是最新]${White}"
		Upgrade_Stopped=1
	} || {
		[[ $(echo ${CLOUD_Firmware_Version} | cut -d "-" -f2) -gt $(echo ${CURRENT_Version} | cut -d "-" -f2) ]] && CURRENT_Type="${Green} [可更新]${White}"
		[[ $(echo ${CLOUD_Firmware_Version} | cut -d "-" -f2) -lt $(echo ${CURRENT_Version} | cut -d "-" -f2) ]] && {
			CLOUD_Type="${Red} [旧版本]${White}"
			Upgrade_Stopped=2
		}
	}
	SHA5BIT=$(echo ${FW_Name} | egrep -o "[a-zA-Z0-9]+.${Firmware_Type}" | sed -r "s/(.*).${Firmware_Type}/\1/")
}

PREPARE_UPGRADES() {
	TITLE
	[[ $* =~ -f && $* =~ -F ]] && SHELL_HELP
	Upgrade_Option="${Upgrade_Command} -q"
	MSG="更新固件"
	while [[ $1 ]];do
		case "$1" in
		-T | --test)
			Test_Mode=1
			Special_Commands="${Special_Commands} [测试模式]"
		;;
		-P | --proxy)
			Proxy_Mode=1
			Special_Commands="${Special_Commands} [镜像加速]"
		;;
		-F)
			[[ -n ${Force_Mode} ]] && SHELL_HELP
			Only_Force_Write=1
			Special_Commands="${Special_Commands} [强制刷写]"
			Upgrade_Option="${Upgrade_Option} -F"
		;;
		--skip)
			Skip_SHA256=1
			Special_Commands="${Special_Commands} [跳过 SHA256 验证]"
		;;
		-f)
			[[ -n ${Only_Force_Write} ]] && SHELL_HELP
			Force_Mode=1
			Special_Commands="${Special_Commands} [强制模式]"
			Upgrade_Option="${Upgrade_Option} -F"
		;;
		-n)
			Upgrade_Option="${Upgrade_Option} -n"
			Special_MSG=" (不保留配置)"
		;;
		-u)
			AutoUpdate_Mode=1
			Special_Commands="${Special_Commands} [定时更新]"
		;;
		path=/*)
			[[ -z $(echo $1 | cut -d "=" -f2) ]] && ECHO r "固件保存路径不能为空!" && EXIT 1
			AutoUpdate_Path=$(echo $1 | cut -d "=" -f2)
			ECHO g "使用自定义固件保存路径: ${AutoUpdate_Path}"
		;;
		--verbose)
			Special_Commands="${Special_Commands} [打印详细信息]"
		;;
		*)
			SHELL_HELP
		esac
	shift
	done
	LOGGER "Upgrade Options: ${Upgrade_Option}"
	[[ -n "${Special_Commands}" ]] && ECHO g "特殊指令:${Special_Commands} / ${Upgrade_Option}"
	ECHO g "执行: ${MSG}${Special_MSG}"
	REMOVE_CACHE quiet
	if [[ $(CHECK_PKG curl) == true && ${Proxy_Mode} != 1 ]];then
		Google_Check=$(curl -I -s --connect-timeout 3 google.com -w %{http_code} | tail -n1)
		[[ ${Google_Check} != 301 ]] && {
			ECHO r "Google 连接失败,优先使用镜像加速!"
			Proxy_Mode=1
		}
	fi
	CHECK_UPDATES continue
	[[ -z ${CLOUD_Firmware_Version} ]] && {
		ECHO r "云端固件信息获取失败!"
		EXIT 1
	}
	[[ ${Proxy_Mode} == 1 ]] && {
		FW_URL="${Release_FastGit_URL}"
	} || FW_URL="${Release_URL}"
	cat <<EOF

固件作者: ${FW_Author%/*}
设备名称: $(uname -n) / ${TARGET_PROFILE}
$([[ ${TARGET_PROFILE} == x86_64 ]] && echo "固件格式: ${Firmware_Type} / ${x86_64_Boot}" || echo "固件格式: ${Firmware_Type}")

$(echo -e "当前固件版本: ${CURRENT_Version}${CURRENT_Type}")
$(echo -e "云端固件版本: ${CLOUD_Firmware_Version}${CLOUD_Type}")

云端固件名称: ${FW_Name}
固件下载地址: ${FW_URL}
EOF
	GET_FW_LOG -v ${CLOUD_Firmware_Version}
	rm -f ${AutoUpdate_Path}/Github_Tags
	case "${Upgrade_Stopped}" in
	1 | 2)
		[[ ${AutoUpdate_Mode} == 1 ]] && ECHO y "已是最新版本,无需更新!" && EXIT 0
		[[ ${Upgrade_Stopped} == 1 ]] && MSG="已是最新版本" || MSG="云端固件版本为旧版"
		[[ ! ${Force_Mode} == 1 ]] && {
			ECHO && read -p "${MSG},是否继续更新固件?[Y/n]:" Choose
		} || Choose=Y
		[[ ! ${Choose} =~ [Yy] ]] && EXIT 0
	;;
	esac
	Retry_Times=5
	ECHO "${Proxy_Echo}正在下载固件,请耐心等待 ..."
	while [[ ${Retry_Times} -ge 0 ]];do
		if [[ ! ${PROXY_Mode} == 1 && ${Retry_Times} == 4 ]];then
			ECHO g "尝试使用 [FastGit] 镜像加速下载固件!"
			FW_URL="${Release_FastGit_URL}"
		fi
		[[ ${Retry_Times} == 3 ]] && {
			ECHO g "尝试使用 [Github Proxy] 镜像加速下载固件!"
			FW_URL="${Release_Goproxy_URL}"
		}
		[[ ${Retry_Times} == 2 ]] && FW_URL="${Github_Release_URL}"
		if [[ ${Retry_Times} == 0 ]];then
			ECHO r "固件下载失败,请检查网络后重试!"
			EXIT 1
		else
			${Downloader} ${AutoUpdate_Path}/${FW_Name} "${FW_URL}/${FW_Name}"
			[[ $? == 0 && -s ${AutoUpdate_Path}/${FW_Name} ]] && ECHO y "固件下载成功!" && break
		fi
		Retry_Times=$((${Retry_Times} - 1))
		ECHO r "固件下载失败,剩余尝试次数: ${Retry_Times} 次"
	done
	if [[ ! ${Skip_SHA256} == 1 ]];then
		CURRENT_SHA256=$(GET_SHA256SUM ${AutoUpdate_Path}/${FW_Name} 5)
		CLOUD_SHA256=$(echo ${FW_Name} | egrep -o "[0-9a-z]+.${Firmware_Type}" | sed -r "s/(.*).${Firmware_Type}/\1/")
		[[ ${CURRENT_SHA256} != ${CLOUD_SHA256} ]] && {
			ECHO r "本地固件 SHA256 与云端比对校验失败 [${CURRENT_SHA256}],请检查网络后重试!"
			EXIT 1
		}
	fi
	case "${Firmware_Type}" in
	img.gz)
		ECHO "正在解压固件,请耐心等待 ..."
		gzip -d -q -f -c ${AutoUpdate_Path}/${FW_Name} > ${AutoUpdate_Path}/$(echo ${FW_Name} | sed -r 's/(.*).gz/\1/')
		[[ $? != 0 ]] && {
			ECHO r "固件解压失败,请检查网络稳定性或更换固件保存路径!"
			EXIT 1
		} || {
			FW_Name="$(echo ${FW_Name} | sed -r 's/(.*).gz/\1/')"
			ECHO "固件解压成功,固件已解压到: ${AutoUpdate_Path}/${FW_Name}"
		}
	;;
	esac
	[[ ${Test_Mode} != 1 ]] && {
		chmod 777 ${AutoUpdate_Path}/${FW_Name}
		DO_UPGRADE ${Upgrade_Option} ${AutoUpdate_Path}/${FW_Name}
	} || {
		ECHO x "[测试模式] ${Upgrade_Option} ${AutoUpdate_Path}/${FW_Name}"
		ECHO x "[测试模式] 运行完毕!"
		EXIT 0
	}
}

DO_UPGRADE() {
	ECHO r "准备更新固件,更新期间请不要断开电源或重启设备 ..."
	sleep 5
	ECHO g "正在更新固件,请耐心等待 ..."
	$*
	[[ $? -ne 0 ]] && {
		ECHO r "固件刷写失败,请尝试手动更新固件!"
		EXIT 1
	} || EXIT 0
}

REMOVE_CACHE() {
	rm -rf ${AutoUpdate_Path}/AutoBuild-${TARGET_PROFILE}-* \
		${AutoUpdate_Path}/Github_Tags \
		${AutoUpdate_Path}/Update_Logs.json
	case "$1" in
	quiet)
		LOGGER "AutoUpdate 缓存清理完成!"
	;;
	*)
		ECHO y "AutoUpdate 缓存清理完成!"
		EXIT 0
	;;
	esac
}

AutoUpdate_LOG() {
	[[ -z $1 ]] && {
		[[ -s ${AutoUpdate_Log_Path}/AutoUpdate.log ]] && {
			TITLE && echo
			cat ${AutoUpdate_Log_Path}/AutoUpdate.log
		}
	} || {
		while [[ $1 ]];do
			case $1 in
			path=/* | rm | del)
				:
			;;
			*)
				SHELL_HELP
			;;
			esac
			if [[ $1 =~ path= ]];then
				LOG_PATH="$(echo $1 | cut -d "=" -f2)"
				[[ ${LOG_PATH} == ${AutoUpdate_Log_Path} ]] && {
					ECHO y "AutoUpdate 日志保存路径相同,无需修改!"
					EXIT 0
				}
				[[ -f ${LOG_PATH} ]] && {
					ECHO r "错误的参数: [${LOG_PATH}]"
					ECHO r "AutoUpdate 日志保存路径有误,请重新输入!"
					EXIT 1
				}
				EDIT_VARIABLE rm ${Custom_Variable} AutoUpdate_Log_Path
				EDIT_VARIABLE edit ${Custom_Variable} AutoUpdate_Log_Path ${LOG_PATH}
				[[ ! -d ${LOG_PATH} ]] && mkdir -p ${LOG_PATH}
				[[ -f ${AutoUpdate_Log_Path}/AutoUpdate.log ]] && mv ${AutoUpdate_Log_Path}/AutoUpdate.log ${LOG_PATH}
				AutoUpdate_Log_Path=${LOG_PATH}
				ECHO y "AutoUpdate 日志保存路径已修改为: ${LOG_PATH}"
				EXIT 0
			fi
			[[ $1 == rm || $1 == del ]] && {
				[[ -f ${AutoUpdate_Log_Path}/AutoUpdate.log ]] && rm ${AutoUpdate_Log_Path}/AutoUpdate.log
			}
			EXIT 0
		done
	}
}

AutoUpdate_Main() {
	local Result
	[[ ! -f ${Custom_Variable} ]] && touch ${Custom_Variable}
	LOAD_VARIABLE ${Default_Variable} ${Custom_Variable}
	[[ ! -d ${AutoUpdate_Path} ]] && mkdir -p ${AutoUpdate_Path}
	
	if [[ $(CHECK_PKG wget-ssl) == true ]];then
		Downloader="wget-ssl --quiet --no-check-certificate -T 5 --no-dns-cache -x -O"
		DL="wget-ssl"
	elif [[ $(CHECK_PKG curl) == true ]];then
		Downloader="curl -L -k -m 5 --silent -o"
		DL="curl"
	else
		Downloader="uclient-fetch --quiet --no-check-certificate -T 5 -O"
		DL="uclient-fetch"
	fi

	[[ -z $* ]] && PREPARE_UPGRADES $*
	[[ $1 =~ path= && ! $* =~ -x && ! $* =~ -U ]] && PREPARE_UPGRADES $*
	[[ $1 =~ --skip ]] && PREPARE_UPGRADES $*
	[[ $* =~ -T || $* =~ --verbose ]] && {
		Downloader="$(echo ${Downloader/ --quiet / })"
		Downloader="$(echo ${Downloader/ --silent / })"
	}

	while [[ $1 ]];do
		case "$1" in
		-n | -f | -u | -T | -P | --proxy | -F | --verbose)
			LOGGER "Downloader: ${DL} / ${Downloader}"
			PREPARE_UPGRADES $*
		;;
		--bak)
			shift
			[[ $# -lt 1 || $# -gt 2 ]] && ECHO r "格式错误,示例: [bash $0 --bak /mnt/sda1 Openwrt_Backups.tar.gz]" && EXIT 1
			[[ $# == 2 ]] && {
				[[ ! -d $1 ]] && mkdir -p $1
				FILE="$1/$2"
				[[ -f ${FILE} ]] && FILE="${FILE}-$(RANDOM 5)"
			} || {
				[[ ! -d $1 ]] && mkdir -p $1
				FILE="$1/$(uname -n)-Backups-$(date +%Y-%m-%d)-$(RANDOM 5)"
			}
			[[ ! ${FILE} =~ tar.gz ]] && FILE="${FILE}.tar.gz"
			ECHO "Saving config files to [${FILE}] ..."
			sysupgrade -b "${FILE}" >/dev/null 2>&1
			[[ $? == 0 ]] && {
				ECHO y "系统文件备份成功!"
				ECHO y "保存位置: ${FILE}"
				EXIT 0
			} || {
				ECHO r "备份文件创建失败,请尝试更换保存路径!"
				EXIT 1
			}
		;;
		--clean)
			shift && [[ -n $* ]] && SHELL_HELP
			REMOVE_CACHE
		;;
		--check)
		    shift && [[ -n $* ]] && SHELL_HELP
			CHECK_DEPENDS bash x86:gzip x86:wget-ssl uclient-fetch curl wget openssl which
		;;
		--env)
			shift
			[[ -z $* ]] && LIST_ENV 0 && EXIT 0
			case $1 in
			1 | 2)
				LIST_ENV $1
			;;
			*)
				SHELL_HELP
			;;
			esac
			EXIT 0
		;;
		--log)
			shift
			AutoUpdate_LOG $*
		;;
		--random)
			shift
			[[ $# != 1 || ! $1 =~ [0-9] || $1 == 0 || $1 -gt 30 ]] && SHELL_HELP || {
				RANDOM $1
				EXIT 0
			}
		;;
		--sleep)
			shift
			sleep $1
			EXIT 0
		;;
		--var)
			shift
			[[ $# != 1 ]] && SHELL_HELP
			SHOW_VARIABLE=$(GET_VARIABLE "$1" ${Custom_Variable})
			[[ -z ${SHOW_VARIABLE} ]] && SHOW_VARIABLE=$(GET_VARIABLE "$1" ${Default_Variable})
			echo "${SHOW_VARIABLE}"
			[[ $? == 0 ]] && EXIT 0 || EXIT 1
		;;
		--var-rm)
			shift
			[[ $# != 1 ]] && SHELL_HELP
			EDIT_VARIABLE rm ${Custom_Variable} $1
			[[ $? == 0 ]] && EXIT 0 || EXIT 1
		;;
		-x)
			shift
			while [[ $1 ]];do
				case $1 in
				url=* | path=/*)
					:
				;;
				*)
					SHELL_HELP
				;;
				esac
				if [[ $1 =~ url= ]];then
					[[ $1 =~ url= ]] && {
					[[ -z $(echo $1 | cut -d "=" -f2) ]] && ECHO r "脚本地址不能为空!" && EXIT 1
						AutoUpdate_Script_URL="$(echo $1 | cut -d "=" -f2)"
					}
				fi
				[[ $1 =~ path= ]] && {
					[[ -z $(echo $1 | cut -d "=" -f2) ]] && ECHO r "保存路径不能为空!" && EXIT 1
					SH_SAVE_PATH="$(echo $1 | cut -d "=" -f2)"
				}
				shift
			done
			LOGGER "Downloader: ${Downloader}"
			[[ -z ${SH_SAVE_PATH} ]] && SH_SAVE_PATH=/bin
			UPDATE_SCRIPT ${SH_SAVE_PATH} ${AutoUpdate_Script_URL}
		;;
		-B)
			shift
			[[ ${TARGET_PROFILE} != x86_64 ]] && SHELL_HELP
			CHANGE_BOOT $1
		;;
		-C)
			shift
			CHANGE_GITHUB $1
		;;
		-E)
			shift
			[[ -z $1 ]] && GET_FW_LOG local show && EXIT 0
			case $1 in
			cloud)
				GET_FW_LOG $1 show
			;;
			*)
				[[ ! $1 =~ R ]] && SHELL_HELP || GET_FW_LOG -v $1 show
			;;
			esac
			EXIT
		;;
		-H | --help)
			SHELL_HELP
		;;
		-L | --list)
			shift && [[ -n $* ]] && SHELL_HELP
			SHOW_VARIABLE
		;;
		-Q)
			shift
			[[ -z $* ]] && {
				echo ${CURRENT_Version}
				EXIT 0
			}
			case $1 in
			cloud | Cloud)
				GET_CLOUD_VERSION
				[[ -z ${CLOUD_Firmware_Version} ]] && echo "未知" || echo "${CLOUD_Firmware_Version}"
			;;
			esac
			EXIT 0
		;;
		-V)
			shift
			case "$1" in
			cloud)
				Result="$(${Downloader} - ${AutoUpdate_Script_URL} | egrep -o "V[0-9].+")"
			;;
			*)
				Result=${Version}
			esac
			[[ -z ${Result} ]] && echo "未知" || {
				LOGGER "Command Result: ${Result}"
				echo "${Result}"
				EXIT 0
			}
		;;
		*)
			SHELL_HELP
		;;
		esac
		shift
	done
}

Version=V6.4.4
AutoUpdate_Path=/tmp/AutoUpdate
AutoUpdate_Log_Path=/tmp
AutoUpdate_Script_URL=https://ghproxy.com/https://raw.githubusercontent.com/Hyy2001X/AutoBuild-Actions/master/Scripts/AutoUpdate.sh
Upgrade_Command=sysupgrade
Default_Variable=/etc/AutoBuild/Default_Variable
Custom_Variable=/etc/AutoBuild/Custom_Variable
[[ -n $* ]] && Run_Command="$0 $*" || Run_Command="$0"

White="\e[0m"
Yellow="\e[33m"
Red="\e[31m"
Blue="\e[34m"
Grey="\e[36m"
Green="\e[32m"

AutoUpdate_Main $*