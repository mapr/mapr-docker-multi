MapR Docker Multi-Container Cluster set-up README.md
====================================================


Docker Requirements and set-up:
-------------------------------
	1. Docker v1.6.0 or later is required to run this set-up script.

	2. Docker Network : Docker containers MapR cluster require public IPs. Please work with your IT to get a routable IP network range for the docker bridge.
		- Configure a Network brige with an IP from the routable IP range.
		- Add the following options to the docker daemon : '-b <bridgename> --fixed-cidr=cidr-or-routable-range'
			Eg: '-b br0 --fixed-cidr=10.10.101.16/29' - This makes docker to allocate the IPs 10.10.101.17 - 10.10.101.22 (6 IPs). 

	3. (optional) Docker Disk options: Please add the following options to the docker daemon : '--storage-opt dm.basesize=30G --storage-opt dm.loopdatasize=200G'

	4. Restart the docker daemon with the above options.

Container Requirement: 
----------------------
	Each container in the cluster requires at least one disk. Please make sure enough number of free disks are there in the system.
	Create a disk list file with one disk/partition per line.
	Eg:
	 # cat /tmp/disklist.txt 
	/dev/sdb
	/dev/sdc
	/dev/sdd
	/dev/sde
	/dev/sdf
	#

Script : launch-cluster.sh

Go to the dir where the script is downloaded to and run:
Usage : ./launch-cluster.sh ClusterName NumberOfNodes MemSize-in-kB Path-to-DisklistFile 
 	Eg: ./launch-cluster.sh demo 3 24576000 /tmp/diskfile.txt 
	This will launch 3 nodes with 24GB mem for each containers and creates a cluster with 3 nodes.
