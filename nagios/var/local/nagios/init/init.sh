#!/bin/bash

if [ $# -ne 2 ]
then
	echo "Usage - $0 datapower_name datapower_address"
	exit 1
fi

datapower_name=$1
datapower_address=$2

#########################################
#step 1 - modifier fichier de conf nagios
#########################################

echo "[1][INFO] Check nagios.cfg"

isfirstinit=`grep dsa /opt/nagios/etc/nagios.cfg`
if [ "$isfirstinit" = "" ]
then
	echo "[1][INFO] Add /var/local/nagios/dsa to nagios.cfg"
	echo "cfg_dir=/var/local/nagios/dsa" >> /opt/nagios/etc/nagios.cfg
else
	echo "[1][INFO] nagios.cfg already setup"
fi

#########################################
#step 2 - creer fichier datapower.cfg
#########################################

echo "[2][INFO] Create or modify /var/local/nagios/dsa/"$datapower_name".cfg"

FILE="/var/local/nagios/dsa/"$datapower_name".cfg"
replacefile="yes"
if [ -f "$FILE" ]
then

	read -p $FILE" Already exists, do you wish to replace this file ? [Yy|Nn] " yn
	case $yn in
		[Yy]* ) rm $FILE; replacefile="yes";;
		[Nn]* ) replacefile="no";;
		* ) echo "Please answer yes or no.";;
	esac

fi

if [ "$replacefile" = "yes" ]
then
	echo "[2][INFO] Create "$FILE
	cat <<EOF >$FILE
define host{
		use					 dsa-server
		host_name			   dsa
		alias				   DSA XI52 VAL/DEV/INF
		address				 dsa
}
EOF
else
	echo "[2][INFO] "$FILE "unmodified"
fi

#########################################
#step 3 - modifier fichier hostgroup
#########################################

echo "[3][INFO] Modify datapower_hostgroup.cfg"

members=`cat /var/local/nagios/dsa/datapower_hostgroup.cfg | grep members`
isfirstmember=`cat /var/local/nagios/dsa/datapower_hostgroup.cfg | grep members | awk -F ' ' '{print $1}'`
HG_FILE="/var/local/nagios/dsa/datapower_hostgroup.cfg"

if [ $isfirstmember = "#" ]
then
	echo "[3][INFO] "$datapower_name" is the first member"
	cat <<EOF1 >$HG_FILE
define hostgroup{
		hostgroup_name  dsa
		alias		   DataPower
		members		 $datapower_name
}

EOF1

else
	memberexists=`grep $datapower_name $HG_FILE`
	if [ "$memberexists" != "" ]
	then
		echo "[3][INFO] "$datapower_name" already in member list"
	else
		cat <<EOF2 >$HG_FILE
define hostgroup{
		hostgroup_name  dsa
		alias		   DataPower
$members,$datapower_name
}

EOF2
	fi
fi
