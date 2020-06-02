#!/bin/bash

FNAME="$1"
LINIT="$2"
ASSETNUM="$3"
MODELNUM="$4"
ADMINPASSWD="$5"
USERNAME=$(echo $FNAME.$LINIT | tr '[:upper:]' '[:lower:]')
echo "$FNAME $LINIT's Macbook login password:" > /Users/bibliocommons-admin/repos/its/macos_new_user/password
PASSWD="$(python password.py | tee -a /Users/bibliocommons-admin/repos/its/macos_new_user/password)"
let UNIQUEID=$(dscl . -list /Users UniqueID | sort -nr -k 2 | head -1 | awk '{ print $2 }')+1

if [[ `id -u` != 0 ]]; then
    echo "Must be root to run script"
    exit 1
fi

if [ "$#" -ne 5 ]
then
	echo "Usage: ./macos_new_user.sh <firstname> <initial of lastname> <asset number> <laptop model number> <admin password>"
	exit 2
fi

if [ $(dscl . list /Users | grep -i -w $FNAME$LINIT | wc -l) -eq 0 ]
then
	# change hostname/computername
	scutil --set ComputerName "$ASSETNUM-$MODELNUM"
	scutil --set LocalHostName "$ASSETNUM-$MODELNUM"
	scutil --set HostName "$ASSETNUM-$MODELNUM"

	# create a user account
	dscl . -create /Users/"$USERNAME"
	dscl . -create /Users/"$USERNAME" UserShell /bin/bash
	dscl . -create /Users/"$USERNAME" RealName "$FNAME $LINIT"
	dscl . -create /Users/"$USERNAME" UniqueID "$UNIQUEID"
	dscl . -create /Users/"$USERNAME" PrimaryGroupID "20"
	dscl . -create /Users/"$USERNAME" NFSHomeDirectory /Users/"$USERNAME"
	dscl . -passwd /Users/"$USERNAME" "$PASSWD"
	dscl . -append /Groups/admin GroupMembership "$USERNAME"

	# enable firewall
	/usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

	# enable filevault
	sed -i '.bak' 's/adminpassword/$ADMINPASSWD/g' /Users/bibliocommons-admin/repos/its/macos_new_user/fdesetup.plist
	sed -i '.bak' 's/username/$USERNAME/g' /Users/bibliocommons-admin/repos/its/macos_new_user/fdesetup.plist
	sed -i '.bak' 's/password/$PASSWD/g' /Users/bibliocommons-admin/repos/its/macos_new_user/fdesetup.plist
	fdesetup enable -inputplist < /Users/bibliocommons-admin/repos/its/macos_new_user/fdesetup.plist | tee /Users/bibliocommons-admin/repos/its/macos_new_user/recoverykey

	# get and unzip standard VPN profile
	mkdir /Users/bibliocommons-admin/openvpn
	unzip /Users/bibliocommons-admin/repos/its/macos_new_user/standard.zip -d /Users/bibliocommons-admin/openvpn

	# download viscosity
	wget https://www.sparklabs.com/downloads/Viscosity.dmg -P /Users/bibliocommons-admin/Downloads

	# install viscosity
	hdiutil attach /Users/bibliocommons-admin/Downloads/Viscosity.dmg
	cp -R /Volume/Viscosity/Viscosity.app /Applications/
	hdiutil detach /Volume/Viscosity

	# download avast
	wget https://bits-server-02.ff.avast.com/download/7/5/d/75d86d19bc69460da5c3b2111e9c9001/avast_business_antivirus_managed.dmg -P /Users/bibliocommons-admin/Downloads

	# install avast
	hdiutil attach /Users/bibliocommons-admin/Downloads/avast_business_antivirus_managed.dmg
	installer /Volume/Avast\ Business\ Antivirus/Avast\ Business\ Antivirus.pkg -target /
	hdiutil detach /Volume/Avast\ Business\ Antivirus

	# add a network printer
	lpadmin -p "black&white" -L "BiblioCommons Office" -E -v ipp://192.168.80.2 -P /Library/Printers/PPDs/Contents/Resources/HP\ LaserJet\ 600\ M601\ M602\ M603.gz

else
	echo "The user $FNAME $LINIT exists. Please try again"
	exit 3
fi
