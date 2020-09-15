#!/bin/bash

Github=https://github.com/CurssedCoffin/Openwrt-AutoUpdate

ExtraPackages_GIT() {
[ -d ./package/lean/$1 ] && rm -rf ./package/lean/$1
while [ ! -f $1/Makefile ]
do
	git clone -b $3 $2/$1 $1
done
mv $1 ./package/lean
}

ExtraPackages_SVN() {
[ -d ./package/lean/$1 ] && rm -rf ./package/lean/$1
while [ ! -f $1/Makefile ]
do
	echo "Checking out $1 from $2 ..."
	svn checkout $2/$1 $1 > /dev/null 2>&1
done
echo "Package $1 detected!"
mv $1 ./package/lean
}

sed -i "s/#src-git helloworld/src-git helloworld/g" feeds.conf.default
ExtraPackages_GIT luci-theme-argon https://github.com/jerrykuku 18.06
ExtraPackages_SVN luci-app-openclash https://github.com/vernesong/OpenClash/trunk
ExtraPackages_SVN luci-app-adguardhome https://github.com/Lienol/openwrt/trunk/package/diy
ExtraPackages_SVN luci-app-smartdns https://github.com/project-openwrt/openwrt/trunk/package/ntlf9t
ExtraPackages_SVN smartdns https://github.com/project-openwrt/openwrt/trunk/package/ntlf9t
[ -d ./Openwrt-AutoUpdate ] && rm -rf ./Openwrt-AutoUpdate
git clone $Github
mv Openwrt-AutoUpdate/AutoUpdate.sh ./package/base-files/files/bin
