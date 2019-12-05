#!/bin/sh
# 参考：https://github.com/AliyunContainerService/kubernetes-issues-solution/blob/master/kubelet/kubelet.sh
# 1. fix_orphanedPod(v1.15.0)
# 2. fix_orphanedPod_subpaths(v1.15.0)

date_echo() {
    echo `date "+%H:%M:%S-%Y-%m-%d"` $1
}

date_echo "Starting to fix the possible issue..."

# fix Orphaned pod, umount the mntpoint;
fix_orphanedPod(){
    secondPart=`echo $item | awk -F"Orphaned pod" '{print $2}'`
    podid=`echo $secondPart | awk -F"\"" '{print $2}'`
	
    # not process if the volume directory is not exist.
    if [ ! -d /var/lib/kubelet/pods/$podid/volumes/ ]; then
        continue
    fi
	
    # umount subpath if exist
    if [ -d /var/lib/kubelet/pods/$podid/volume-subpaths/ ]; then
        mountpath=`mount | grep /var/lib/kubelet/pods/$podid/volume-subpaths/ | awk '{print $3}'`
        for mntPath in $mountpath;
        do
             date_echo "Fix subpath Issue:: umount subpath $mntPath"
             umount $mntPath
             idleTimes=0
        done
    fi

    volumeTypes=`ls /var/lib/kubelet/pods/$podid/volumes/`
    for volumeType in $volumeTypes;
    do
         subVolumes=`ls -A /var/lib/kubelet/pods/$podid/volumes/$volumeType`
         if [ "$subVolumes" != "" ]; then
             date_echo "/var/lib/kubelet/pods/$podid/volumes/$volumeType contents volume: $subVolumes"
             for subVolume in $subVolumes;
             do
                 if [ "$volumeType" == "kubernetes.io~csi" ]; then
                     # check subvolume path is mounted or not
                     findmnt /var/lib/kubelet/pods/$podid/volumes/$volumeType/$subVolume/mount
                     if [ "$?" != "0" ]; then
                         date_echo "/var/lib/kubelet/pods/$podid/volumes/$volumeType/$subVolume/mount is not mounted, just need to remove"
                         content=`ls -A /var/lib/kubelet/pods/$podid/volumes/$volumeType/$subVolume/mount`
                         # if path is empty, just remove the directory.
                         if [ "$content" = "" ]; then
                             rmdir /var/lib/kubelet/pods/$podid/volumes/$volumeType/$subVolume/mount || true
                             rm -f /var/lib/kubelet/pods/$podid/volumes/$volumeType/$subVolume/vol_data.json || true
                             rmdir /var/lib/kubelet/pods/$podid/volumes/$volumeType/$subVolume || true
                         # if path is not empty, do nothing.
                         else
                             date_echo "/var/lib/kubelet/pods/$podid/volumes/$volumeType/$subVolume/mount is not mounted, but not empty"
                             idleTimes=0
                         fi
                     # is mounted, umounted it first.
                     else
                         date_echo "Fix orphaned Issue:: /var/lib/kubelet/pods/$podid/volumes/$volumeType/$subVolume/mount is mounted, umount it"
                         umount /var/lib/kubelet/pods/$podid/volumes/$volumeType/$subVolume/mount
                     fi
                 else
                     # check subvolume path is mounted or not
                     findmnt /var/lib/kubelet/pods/$podid/volumes/$volumeType/$subVolume
                     if [ "$?" != "0" ]; then
                         date_echo "/var/lib/kubelet/pods/$podid/volumes/$volumeType/$subVolume is not mounted, just need to remove"
                         content=`ls -A /var/lib/kubelet/pods/$podid/volumes/$volumeType/$subVolume`
                         # if path is empty, just remove the directory.
                         if [ "$content" = "" ]; then
                             rmdir /var/lib/kubelet/pods/$podid/volumes/$volumeType/$subVolume
                         # if path is not empty, do nothing.
                         else
                             date_echo "/var/lib/kubelet/pods/$podid/volumes/$volumeType/$subVolume is not mounted, but not empty"
                             idleTimes=0
                         fi
                     # is mounted, umounted it first.
                     else
                         date_echo "Fix orphaned Issue:: /var/lib/kubelet/pods/$podid/volumes/$volumeType/$subVolume is mounted, umount it"
                         umount /var/lib/kubelet/pods/$podid/volumes/$volumeType/$subVolume
                     fi
                 fi
             done
         fi
    done
	date_echo "fix_orphanedPod done. podid=$podid"
}

# fix orphaned pod
fix_orphanedPod_subpaths(){
    secondPart=`echo $item | awk -F"orphaned pod" '{print $2}'`
    podid=`echo $secondPart | awk -F"\"" '{print $2}'`
	rm -rf /var/lib/kubelet/pods/$podid
	date_echo "fix_orphanedPod_subpaths done. podid=$podid"
}


idleTimes=0
IFS=$'\r\n'
while :
do
    for item in `tail /var/log/messages`;
    do
        ## orphaned pod process
        # kubelet_volumes.go:154] Orphaned pod "4fda88ab-9cf7-471f-bbb1-172e02fb78d4" found, but volume paths are still present on disk : There were a total of 1 errors similar to this. Turn up verbosity to see them.
		if [[ $item == *"Orphaned pod"* ]] && [[ $item == *"but volume paths are still present on disk"* ]]; then
			fix_orphanedPod $item
		# kubelet: E1205 11:41:40.268005    1913 kubelet_volumes.go:154] orphaned pod "5224b4b0-9442-4169-965b-ed56cb879e54" found, but volume [paths|subpaths] are still present on disk : There were a total of 8 errors similar to this. Turn up verbosity to see them.
		elif [[ $item == *"orphaned pod"* ]] && [[ $item == *"but volume"* ]]; then
			fix_orphanedPod_subpaths $item
        fi
    done

    idleTimes=`expr $idleTimes + 1`
    if [ "$idleTimes" = "10" ] && [ "$LONGRUNNING" != "True" ]; then
        break
    fi
    sleep 5
done

date_echo "Finish Process......"