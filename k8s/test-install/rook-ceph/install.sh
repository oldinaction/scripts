cd /root/k8s/rook-1.1.2/cluster/examples/kubernetes/ceph
kubectl apply -f common.yaml
kubectl apply -f operator.yaml
kubectl apply -f cluster.yaml
kubectl apply -f dashboard-external-https.yaml
kubectl -n rook-ceph get service
