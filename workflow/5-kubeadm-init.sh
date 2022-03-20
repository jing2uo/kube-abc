export VIP="192.168.137.248"
export PODSUBNET="10.244.0.0/16"
export SVCSUBNET="10.96.0.0/12"

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
kubernetesVersion: 1.23.0
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
