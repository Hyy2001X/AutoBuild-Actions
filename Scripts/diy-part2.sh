#!/bin/bash

Author=CurssedCoffin
Date=`date +%Y/%m/%d`
DefaultFile=./package/lean/default-settings/files/zzz-default-settings
Version=`egrep -o "R[0-9]+\.[0-9]+\.[0-9]+" $DefaultFile`

if [ ! $(grep -o "Compiled by $Author" $DefaultFile | wc -l) = "1" ];then
	sed -i "s?$Version?$Version Compiled by $Author [$Date]?g" $DefaultFile
fi
Old_Date=`egrep -o "[0-9]+\/[0-9]+\/[0-9]+" $DefaultFile`
if [ ! $Date == $Old_Date ];then
	sed -i "s?$Old_Date?$Date?g" $DefaultFile
fi
echo "$Version-`date +%Y%m%d`" > ./package/base-files/files/etc/openwrt_date
