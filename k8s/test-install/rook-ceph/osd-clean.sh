#!/bin/bash

sudo rm -rf /var/lib/rook
# 卸载rook数据目录
sudo umount /data/rook
sudo sgdisk --zap-all /dev/vdb
sudo /usr/sbin/wipefs --all /dev/vdb
# 在每个节点上删除映射
sudo ls /dev/mapper/ceph-* | xargs -I% -- dmsetup remove %
sudo rm -rf /dev/mapper/ceph-*
sudo rm -rf /dev/ceph-*
sudo rm -rf /data/rook
