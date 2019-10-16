kubectl -n rook-ceph delete cephcluster rook-ceph
cd /root/k8s/rook-1.1.2/cluster/examples/kubernetes/ceph
kubectl delete -f operator.yaml
kubectl delete -f common.yaml
