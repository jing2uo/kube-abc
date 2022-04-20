export IFACE=$(ip route | grep default | awk '{print $5}')
export OWNIP=$(ip a s ${IFACE} | egrep -o 'inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d' ' -f2)

echo ${OWNIP} >/tmp/ownip

add_sysctl() {
  echo "### 添加 sysctl 配置"
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
}

close_selinux() {
  echo "### 关闭 selinux"
  setenforce 0
  sed -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config
}

close_swap() {
  echo "### 关闭 swap"
  swapoff -a
  sed -i '/swap/d' /etc/fstab
}

close_firewall() {
  echo "### 关闭防火墙"
  systemctl stop firewalld && systemctl disable firewalld
}

install_app() {
  echo "### 安装常用软件"
  sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^#baseurl=http://mirror.centos.org|baseurl=https://opentuna.cn|g' \
    -i.bak /etc/yum.repos.d/CentOS-*.repo
  yum -y -q install chrony && systemctl enable chronyd && systemctl start chronyd
  yum install -y -q conntrack ipvsadm bind-utils net-tools psmisc
}

add_modules() {
  echo "### 加载必要模块"
  cat >/etc/sysconfig/modules/k8s.modules <<EOF
modprobe ip_vs
modprobe ip_vs_rr
modprobe ip_vs_wrr
modprobe ip_vs_sh
modprobe nf_conntrack_ipv4
modprobe br_netfilter
EOF
  cat /etc/sysconfig/modules/k8s.modules | sudo bash
}

install_docker() {
  echo "### 安装 docker"
  cat <<EOF >/etc/yum.repos.d/docker-ce.repo
[docker-ce]
name=docker-ce
baseurl=https://opentuna.cn/docker-ce/linux/centos/\$releasever/\$basearch/stable
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
  yum install docker-ce -y -q
  systemctl stop docker && rm -rf /var/lib/docker && systemctl start docker && systemctl enable docker
}

get_kube_version() {
  curl -s -k https://mirrors.tuna.tsinghua.edu.cn/kubernetes/yum/repos/kubernetes-el7-x86_64/Packages/ -o /tmp/xxx.html && grep kubeadm /tmp/xxx.html | awk -F'-' '{print $3}' | sort -V >/tmp/kube_version && rm /tmp/xxx.html -rf
  if [[ $1 == '' ]]; then
    export KUBE_VERSION=$(tail -n1 /tmp/kube_version)
  elif [[ $(grep $1 /tmp/kube_version | wc -l) -eq 1 ]]; then
    export KUBE_VERSION=$1
  else
    cat /tmp/kube_version && echo "输入了不会安装的 kubernetes 版本 $1，当前支持以上版本" && exit 1
  fi
}

install_kube() {
  echo "### 安装 kubeadm kubelet kubectl"
  cat <<EOF >/etc/yum.repos.d/kube.repo
[kubernetes]
name=kubernetes
baseurl=https://opentuna.cn/kubernetes/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=0
EOF
  yum install kubeadm-${KUBE_VERSION} kubelet-${KUBE_VERSION} kubectl-${KUBE_VERSION} -y -q && systemctl enable kubelet
}

kube_init_one_node() {
  echo "### 初始化 kubernetes ${KUBE_VERSION}"
  kubeadm config print init-defaults >/tmp/kubeadm.yaml
  sed -i 's|imageRepository:\ k8s.gcr.io|imageRepository:\ registry.aliyuncs.com/google_containers|g' /tmp/kubeadm.yaml
  sed -i "s|advertiseAddress:\ 1.2.3.4|advertiseAddress:\ ${OWNIP}|g" /tmp/kubeadm.yaml
  sed -i "s|name:.*|name:\ ${OWNIP}|g" /tmp/kubeadm.yaml
  sed -i -e "s|kubernetesVersion:.*|kubernetesVersion:\ ${KUBE_VERSION}|g" /tmp/kubeadm.yaml
  sed -i "/networking/a\  podSubnet: ${PODSUBNET}" /tmp/kubeadm.yaml
  kubeadm init --upload-certs --config /tmp/kubeadm.yaml
  mkdir -p $HOME/.kube
  cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  chown $(id -u):$(id -g) $HOME/.kube/config

}

kube_init_ha() {
  cat <<EOF >>kubeadm.yaml
apiServer:
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta3
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager: {}
dns: {}
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: registry.aliyuncs.com/google_containers
kind: ClusterConfiguration
kubernetesVersion: ${KUBE_VERSION}
controlPlaneEndpoint: "${VIP}:6443"
networking:
  podSubnet: ${PODSUBNET}
  dnsDomain: cluster.local
  serviceSubnet: ${SVCSUBNET}
scheduler: {}
EOF
  kubeadm init --upload-certs --config kubeadm.yaml
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
}

install_flannel() {
  echo "### 安装 flannel"
  cat <<EOF >/tmp/kube-flannel.yaml
---
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: psp.flannel.unprivileged
  annotations:
    seccomp.security.alpha.kubernetes.io/allowedProfileNames: docker/default
    seccomp.security.alpha.kubernetes.io/defaultProfileName: docker/default
    apparmor.security.beta.kubernetes.io/allowedProfileNames: runtime/default
    apparmor.security.beta.kubernetes.io/defaultProfileName: runtime/default
spec:
  privileged: false
  volumes:
  - configMap
  - secret
  - emptyDir
  - hostPath
  allowedHostPaths:
  - pathPrefix: "/etc/cni/net.d"
  - pathPrefix: "/etc/kube-flannel"
  - pathPrefix: "/run/flannel"
  readOnlyRootFilesystem: false
  # Users and groups
  runAsUser:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  fsGroup:
    rule: RunAsAny
  # Privilege Escalation
  allowPrivilegeEscalation: false
  defaultAllowPrivilegeEscalation: false
  # Capabilities
  allowedCapabilities: ['NET_ADMIN', 'NET_RAW']
  defaultAddCapabilities: []
  requiredDropCapabilities: []
  # Host namespaces
  hostPID: false
  hostIPC: false
  hostNetwork: true
  hostPorts:
  - min: 0
    max: 65535
  # SELinux
  seLinux:
    # SELinux is unused in CaaSP
    rule: 'RunAsAny'
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: flannel
rules:
- apiGroups: ['extensions']
  resources: ['podsecuritypolicies']
  verbs: ['use']
  resourceNames: ['psp.flannel.unprivileged']
- apiGroups:
  - ""
  resources:
  - pods
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - nodes
  verbs:
  - list
  - watch
- apiGroups:
  - ""
  resources:
  - nodes/status
  verbs:
  - patch
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: flannel
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: flannel
subjects:
- kind: ServiceAccount
  name: flannel
  namespace: kube-system
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: flannel
  namespace: kube-system
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: kube-flannel-cfg
  namespace: kube-system
  labels:
    tier: node
    app: flannel
data:
  cni-conf.json: |
    {
      "name": "cbr0",
      "cniVersion": "0.3.1",
      "plugins": [
        {
          "type": "flannel",
          "delegate": {
            "hairpinMode": true,
            "isDefaultGateway": true
          }
        },
        {
          "type": "portmap",
          "capabilities": {
            "portMappings": true
          }
        }
      ]
    }
  net-conf.json: |
    {
      "Network": "${PODSUBNET}",
      "Backend": {
        "Type": "vxlan"
      }
    }
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: kube-flannel-ds
  namespace: kube-system
  labels:
    tier: node
    app: flannel
spec:
  selector:
    matchLabels:
      app: flannel
  template:
    metadata:
      labels:
        tier: node
        app: flannel
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/os
                operator: In
                values:
                - linux
      hostNetwork: true
      priorityClassName: system-node-critical
      tolerations:
      - operator: Exists
        effect: NoSchedule
      serviceAccountName: flannel
      initContainers:
      - name: install-cni-plugin
       #image: flannelcni/flannel-cni-plugin:v1.0.1 for ppc64le and mips64le (dockerhub limitations may apply)
        image: rancher/mirrored-flannelcni-flannel-cni-plugin:v1.0.1
        command:
        - cp
        args:
        - -f
        - /flannel
        - /opt/cni/bin/flannel
        volumeMounts:
        - name: cni-plugin
          mountPath: /opt/cni/bin
      - name: install-cni
       #image: flannelcni/flannel:v0.17.0 for ppc64le and mips64le (dockerhub limitations may apply)
        image: rancher/mirrored-flannelcni-flannel:v0.17.0
        command:
        - cp
        args:
        - -f
        - /etc/kube-flannel/cni-conf.json
        - /etc/cni/net.d/10-flannel.conflist
        volumeMounts:
        - name: cni
          mountPath: /etc/cni/net.d
        - name: flannel-cfg
          mountPath: /etc/kube-flannel/
      containers:
      - name: kube-flannel
       #image: flannelcni/flannel:v0.17.0 for ppc64le and mips64le (dockerhub limitations may apply)
        image: rancher/mirrored-flannelcni-flannel:v0.17.0
        command:
        - /opt/bin/flanneld
        args:
        - --ip-masq
        - --kube-subnet-mgr
        resources:
          requests:
            cpu: "100m"
            memory: "50Mi"
          limits:
            cpu: "100m"
            memory: "50Mi"
        securityContext:
          privileged: false
          capabilities:
            add: ["NET_ADMIN", "NET_RAW"]
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        volumeMounts:
        - name: run
          mountPath: /run/flannel
        - name: flannel-cfg
          mountPath: /etc/kube-flannel/
        - name: xtables-lock
          mountPath: /run/xtables.lock
      volumes:
      - name: run
        hostPath:
          path: /run/flannel
      - name: cni-plugin
        hostPath:
          path: /opt/cni/bin
      - name: cni
        hostPath:
          path: /etc/cni/net.d
      - name: flannel-cfg
        configMap:
          name: kube-flannel-cfg
      - name: xtables-lock
        hostPath:
          path: /run/xtables.lock
          type: FileOrCreate
EOF

  kubectl apply -f /tmp/kube-flannel.yaml &>/dev/null

}

common_prepare() {
  echo "### 关闭防火墙"
  close_firewall &>>/tmp/kubeabc.log
  echo "### 关闭 selinux"
  close_selinux &>>/tmp/kubeabc.log
  echo "### 关闭 swap"
  close_swap &>>/tmp/kubeabc.log
  echo "### 安装常用软件"
  install_app &>>/tmp/kubeabc.log
  echo "### 添加 sysctl 配置"
  add_sysctl &>>/tmp/kubeabc.log
  echo "### 加载必要模块"
  add_modules &>>/tmp/kubeabc.log
  echo "### 安装 docker"
  install_docker &>>/tmp/kubeabc.log
}
