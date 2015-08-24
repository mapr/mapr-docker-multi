#!/bin/bash

MAPRVER="4.1.0"
# Docker Checks
if [[ -z $(which docker)  ]] ; then
        echo " docker could not be found on this server. Please install Docker version 1.6.0 or later."
	echo " If it is already installed Please update the PATH env variable." 
        exit
fi

dv=$(docker --version | awk '{ print $3}' | sed 's/,//')
if [[ $dv < 1.6.0 ]] ; then
        echo " Docker version installed on this server : $dv.  Please install Docker version 1.6.0 or later."
        exit
fi

# sshpass Checks
if [[ -z $(which sshpass)  ]] ; then
        echo " sshpass could not be found on this server. Please install sshpass."
	echo " If it is already installed Please update the PATH env variable." 
        exit
fi

# Usage Check.
if [[ $# -ne 4 ]]
then
	echo " Usage : $0 ClusterName NumberOfNodes MemSize-in-kB Path-to-DisklistFile"
	exit
fi

CLUSTERNAME=$1
NUMBEROFNODES=$2
MEMTOTAL=$3
DISKLISTFILE=$4

if [[ ! -f ${DISKLISTFILE} ]]
then
	echo " Disklistile : ${DISKLISTFILE} doesn't exist"
	exit
fi


#declare -a disks=(`for i in /dev/sd[a-z]; do   [[ $(sfdisk -l $i | wc -l) -eq 2 ]]  && echo $i; done`)
declare -a disks=(`cat ${DISKLISTFILE}`)

if [[ ${#disks[@]} -eq 0 ]] 
then
	echo "There are no usable disks on this server."
	exit
fi

if [[ ${#disks[@]} -lt ${NUMBEROFNODES} ]] ; then
	echo " Not enough disks to run the requested configuration. "
	echo " This server has ${#disks[@]} disks : ${disks[@]}"
	echo " Each node requires a minimum of one disk. "
	exit
fi

if [[ ${NUMBEROFNODES} -eq 0 ]] ; then
	echo " Bye !"
	exit
fi


declare -a container_ids
declare -a container_ips

# Launch the Control Nodes
cldbdisks=${disks[0]}
function join { local IFS="$1"; shift; echo "$*"; }
if [[ ${NUMBEROFNODES} -lt ${#disks[@]} ]] ; then
	cldbdisks=$(join , ${disks[0]} ${disks[@]:$NUMBEROFNODES})
fi

cldb_cid=$(docker run -d --privileged -h ${CLUSTERNAME}c1 -e "DISKLIST=$cldbdisks" -e "CLUSTERNAME=${CLUSTERNAME}" -e "MEMTOTAL=${MEMTOTAL}" docker.io/maprtech/mapr-control-cent66:${MAPRVER})
container_ids[0]=$cldb_cid

sleep 10
cldbip=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${cldb_cid} )
container_ips[0]=$cldbip
echo "Control Node IP : $cldbip		Starting the cluster: https://${cldbip}:8443/    login:mapr   password:mapr"

sleep 20
# Launch Data Nodes 
i=1
while [[ $i -lt $NUMBEROFNODES ]]
do
  data_cid=$(docker run -d --privileged -h ${CLUSTERNAME}d${i} -e "CLDBIP=${cldbip}" -e "DISKLIST=${disks[$i]}" -e "CLUSTERNAME=${CLUSTERNAME}" -e "MEMTOTAL=${MEMTOTAL}" docker.io/maprtech/mapr-data-cent66:${MAPRVER})
  container_ids[$i]=$data_cid
  sleep 10
  dip=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${data_cid} )
  container_ips[$i]=$dip
  echo -e "$dip\t${CLUSTERNAME}d${i}\t${CLUSTERNAME}d${i}" >> /tmp/hosts.$$
  i=`expr $i + 1`
done


#Populate the /etc/hosts on all the nodes
for ip in "${container_ips[@]}"
do
	sshpass -p "mapr" scp -o LogLevel=quiet -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r /tmp/hosts.$$ ${ip}:/tmp/hosts
	sshpass -p "mapr" ssh -o LogLevel=quiet -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ${ip} 'cat /tmp/hosts >> /etc/hosts'
done

echo -n "Data Nodes : "
join , ${container_ips[@]:1}
