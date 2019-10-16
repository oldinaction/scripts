rm -rf /var/lib/rook
sgdisk --zap-all /dev/sdb
/usr/sbin/wipefs --all /dev/sdb
# 在每个节点上删除映射
ls /dev/mapper/ceph-* | xargs -I% -- dmsetup remove %
rm -rf /dev/mapper/ceph-*
rm -rf /dev/ceph-*
