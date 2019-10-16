#!/bin/bash

## 准备工作
yum update -y

systemctl stop firewalld && systemctl disable firewalld && setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config

# 开启bridge转发
cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
# 关闭系统的Swap，如果不关闭，默认配置下kubelet将无法启动；亦可通过参数设置不关闭Swap。特别是已经运行了其他应用的服务器，可通过参数忽略Swap校验，此时则无需关闭
# vm.swappiness=0
EOF

# 加载内核br_netfilter模块
modprobe br_netfilter
cat > /etc/rc.d/sysinit <<EOF 
#!/bin/bash
for file in /etc/sysconfig/modules/*.modules ; do
[ -x $file ] && $file
done
EOF
cat > /etc/sysconfig/modules/br_netfilter.modules <<EOF
modprobe br_netfilter
EOF
chmod 755 /etc/sysconfig/modules/br_netfilter.modules
# 重启后查看模块是否启动
lsmod |grep br_netfilter

# 开启ipvs
cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF
chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4
yum install -y ipset

# 安装Docker(下列1-3步骤网上部分案例未执行)
yum install -y yum-utils device-mapper-persistent-data lvm2
wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
yum list docker-ce.x86_64 --showduplicates | sort -r # 查看docker版本
yum makecache fast # 更新缓存
yum install -y --setopt=obsoletes=0 docker-ce-18.09.7-3.el7 # 安装docker
systemctl start docker && systemctl enable docker
iptables -nvL | grep 'Chain FORWARD'

# 设置harbor镜像
cat > /etc/docker/daemon.json <<EOF
{"insecure-registries": ["192.168.17.73:2080"]}
EOF

## 安装Kubernetes
# 使用kubeadm部署Kubernetes
cat << EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
yum makecache fast
yum install -y kubeadm-1.15.0 kubelet-1.15.0 kubectl-1.15.0
cat > /etc/sysconfig/kubelet <<EOF
KUBELET_EXTRA_ARGS=--fail-swap-on=false
EOF
systemctl daemon-reload && systemctl enable kubelet

## 重启
echo "==============================================================="
read -p "script end, you are sure you wang to reboot?[y/n]" input
echo "you input [$input]"
if [ $input = "y" ];then
    reboot
fi
