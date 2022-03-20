# sysctl 配置
cat <<EOF >>/etc/sysctl.d/99-k8s.conf
kernel.sem = "250 32000 32 1024"
net.core.netdev_max_backlog = 20000
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.somaxconn = 2048
net.core.wmem_default = 262144
net.core.wmem_max = 16777216
net.ipv4.tcp_ﬁn_timeout = 15
net.ipv4.tcp_max_orphans = 131072
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_mem = "786432 2097152 3145728"
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_forward = 1
net.netﬁlter.nf_conntrack_max = 524288
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
fs.inotify.max_user_watches = 1048576
fs.may_detach_mounts = 1
vm.dirty_background_ratio = 5
vm.dirty_ratio = 10
vm.swappiness = 0
vm.max_map_count = 262144
EOF

sysctl -p

# 关闭 selinux
sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config

# 关闭 swap
sudo swapoff -a
sed -i '/swap/d' /etc/fstab

# 时间同步
yum -y install chrony && systemctl enable chronyd && systemctl start chronyd

# 安装常用软件包
yum install -y conntrack ipvsadm \
               jq curl bind-utils vim net-tools

# 关闭防火墙
systemctl stop firewalld && systemctl disable firewalld

# 加载必须的模块
cat > /etc/sysconfig/modules/k8s.modules <<EOF
modprobe ip_vs
modprobe ip_vs_rr
modprobe ip_vs_wrr
modprobe ip_vs_sh
modprobe nf_conntrack_ipv4
modprobe br_netfilter
EOF

cat /etc/sysconfig/modules/k8s.modules | sudo bash