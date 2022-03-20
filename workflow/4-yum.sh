cat <<EOF >/etc/yum.repos.d/docker-ce.repo
[docker-ce-stable]
name=Docker CE Stable - \$basearch
baseurl=https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/centos/\$releasever/\$basearch/stable
enabled=1
gpgcheck=0
EOF

cat <<EOF >>/etc/yum.repos.d/kube.repo
[kubernetes]
name=kubernetes
baseurl=https://mirrors.tuna.tsinghua.edu.cn/kubernetes/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=0
EOF

mkdir -p /etc/docker
cat <<EOF >/etc/docker/daemon.json
{
  "debug": false,
  "insecure-registries": [
    "0.0.0.0/0"
  ],
  "ip-forward": true,
  "ipv6": false,
  "live-restore": true,
  "log-driver": "json-file",
  "log-level": "warn",
  "log-opts": {
    "max-file": "2",
    "max-size": "100m"
  },
  "exec-opts": ["native.cgroupdriver=systemd"],
  "selinux-enabled": false,
  "metrics-addr": "0.0.0.0:9323",
  "experimental": true
}
EOF

yum install kubeadm docker-ce -y

systemctl stop docker && rm -rf /var/lib/docker && systemctl start docker
