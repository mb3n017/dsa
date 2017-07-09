#!/bin/bash

function usage(){
	printf "Usage :\n"
	printf "\t-n   : DataPower name ;\n"
	printf "\t-d   : DataPower address;\n"
	printf "\t-h   : Display this message.\n"
}

if [ $# -eq 0 ]
then
	usage
fi

while getopts "n:d:" opt; do
  case $opt in
    n)
      datapower_name="$OPTARG"
      ;;
    d)
      datapower_address="$OPTARG"
      ;;
    \?)
      usage
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done


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
	echo ""
	read -p $FILE" Already exists, do you wish to replace this file ? [Yy|Nn] " yn
	case $yn in
		[Yy]* ) rm $FILE; replacefile="yes";;
		[Nn]* ) replacefile="no";;
		* ) echo "Please answer Y|y or N|n.";;
	esac

fi

if [ "$replacefile" = "yes" ]
then
	echo "[2][INFO] Create "$FILE
	cat <<EOF >$FILE
define host{
	use		 dsa-server
	host_name	 $datapower_name
	alias		 DATAPOWER $datapower_name
	address		 $datapower_address
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
	alias		DataPower
	members		$datapower_name
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
	alias		DataPower
$members,$datapower_name
}

EOF2
	fi
fi

