#!/bin/bash

version="v1.1"
para="$1"

if [ "$para" == "-h" ] || [ "$para" == "--help" ]
then
  echo "Clean up the node"
  echo "Usage: cleanup.sh [options] "
  echo ""
  echo "Options:"
  echo -e "\t-h, --help\tPrint help information and exit"
  echo -e "\t-v, --version\tPrint version information and exit"
  exit 0
fi

if [ "$para" == "--version" ] || [ "$para" == "-v" ]
then
  echo $version
  exit 0
fi
echo "Version: $version"
systemctl  stop kubelet
docker rm -f `docker ps -aq`
systemctl restart docker
/usr/local/bin/kubeadm reset -f
/usr/local/bin/kubeadm reset -f
/usr/local/bin/kubeadm reset -f
kubeadm reset -f
kubeadm reset -f
kubeadm reset -f
systemctl disable kubelet
systemctl daemon-reload
systemctl stop kubelet
systemctl stop check-kubelet

docker ps -qa|xargs docker rm -f

systemctl disable containerd
systemctl daemon-reload
systemctl stop containerd
rm -rf /etc/systemd/system/docker.service*
ps -ef | awk '$8=="containerd" {print $2}'| xargs kill

rpm -qa | grep kube | xargs rpm -e
rpm -qa | grep docker | xargs rpm -e
rpm -qa | grep containe | xargs rpm -e

for j in {1..5}
do
    for i in kubelet kubeadm kubectl kubectl-captain helm dockerd docker containerd
    do
        rm -rf $(which $i 2>/dev/null)
    done
done

rm -rf ~/.docker/config.json
rm -rf /etc/containerd/config.toml
rm -rf /var/lib/docker/*
rm -rf /var/lib/containerd/*

ip link set dummy0 down
ip link delete dummy0
ip link set tunl0 down
ip link delete tunl0
ip link set kube-ipvs0
ip link delete kube-ipvs0
ip link set flannel.1 down
ip link set cni0 down
ip link delete flannel.1
ip link delete cni0
ip link del keepalived


rm -rf /etc/kube*
rm -rf /var/lib/kubelet
rm -rf /etc/etcd/
rm -rf /etc/cni/net.d
rm -rf /var/lib/etcd
rm -rf /opt/cni/bin
rm -rf /var/lib/cni/
rm -rf /etc/cni
rm -rf /etc/sysconfig/kubelet
rm -rf /etc/sysconfig/kube-*
rm -rf /etc/sysconfig/flanneld
rm -rf /etc/modules-load.d/tke.conf
rm -rf /etc/sysctl.d/99-tke.conf
rm -rf /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
rm -rf /etc/systemd/system/kubelet.service*
rm -rf /usr/lib/systemd/system/kubelet.service*
rm -rf /usr/lib/systemd/system/docker.service*


rm -rf $HOME/.kube
rm -rf $HOME/.helm
rm -rf $HOME/.ansible/
rm -rf /root/.helm
rm -rf /root/.kube
rm -rf /root/.ansible/

rm -rf /cpaas/*

rm -rf /var/run/openvswitch
rm -rf /var/run/ovn
rm -rf /etc/origin/openvswitch/
rm -rf /etc/origin/ovn/
rm -rf /etc/cni/net.d/00-kube-ovn.conflist
rm -rf /etc/cni/net.d/01-kube-ovn.conflist
rm -rf /var/log/openvswitch
rm -rf /var/log/ovn

rm -rf /usr/lib/systemd/system/kubelet.service.d

df -l --output=target | grep ^/var/lib/kubelet | grep subpath | xargs -r umount
df -l --output=target | grep ^/var/lib/kubelet | xargs -r umount
ip link del ipvlan0
ip link del macvlan0
ip link del tunl0
for i in $(arp -an | grep 'PERM on macvlan0' | awk '{print $2}' | sed -e 's/(//g' -e 's/)//g') ; do arp -i macvlan0 -d $i; done;

iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -t nat -F
iptables -t mangle -F
iptables -F
iptables -X
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

ipvsadm -C

