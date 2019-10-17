#!/bin/bash
# 更新Centos7默认内核版本3.10.0为最新的LTS。使用root用户执行

## 查看版本
uname -r
# 3.10.0-1062.1.2.el7.x86_64
cat /etc/redhat-release
# CentOS Linux release 7.3.1611 (Core)
cat /proc/version
# Linux version 3.10.0-1062.1.2.el7.x86_64 (mockbuild@kbuilder.bsys.centos.org) (gcc version 4.8.5 20150623 (Red Hat 4.8.5-39) (GCC) ) #1 SMP Mon Sep 30 14:19:46 UTC 2019

## 需要先导入elrepo的key，然后安装elrepo的yum源
rpm -import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm

## 安装(也可以把kernel image的rpm包下载下来手动安装)
# 查看可用稳定版本
yum --disablerepo="*" --enablerepo="elrepo-kernel" list available
# 安装长期支持版
yum -y --enablerepo=elrepo-kernel install kernel-lt.x86_64 kernel-lt-devel.x86_64

## 修改grub中默认的内核版本(Linux Kernel)
# 查看所有内核版本，第一行则内核索引为0，以此类推
# awk -F\' '$1=="menuentry " {print $2}' /etc/grub2.cfg
# 修改默认启动内核版本。将 `GRUB_DEFAULT=saved` 改成 `GRUB_DEFAULT=0`(此处0表示新安装的内核索引)
sed -i 's#GRUB_DEFAULT=saved#GRUB_DEFAULT=0#g' /etc/default/grub
# 重新创建内核配置
grub2-mkconfig -o /boot/grub2/grub.cfg

# 可选。删除旧的内核
# rpm -qa | grep kernel
# yum remove 3.10.0-1062.1.2.el7.x86_64

# 重启
read -p "you are sure you wang to reboot?[y/n]" input
echo "you input [$input]"
if [ $input = "y" ];then
    reboot
fi
