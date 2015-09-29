#!/bin/bash

declare -a container_ids
declare -a container_ips

# Launch the Control Nodes

cldb_cid=$(docker run -d --privileged -h maprdemo  docker.io/maprtech/maprdb-json-devpreview:34670)
container_ids[0]=$cldb_cid

cldbip=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${cldb_cid} )
container_ips[0]=$cldbip
echo "Control Node IP : $cldbip		Starting the cluster: https://${cldbip}:8443/    login:mapr   password:mapr"
echo "sshd is enabled"
