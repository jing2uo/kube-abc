export ENDPOINT="CHANGEME"
export PODSUBNET="10.244.0.0/16"
export SVCSUBNET="10.96.0.0/12"

source <(curl -s ${ENDPOINT}/1-function.sh)

if [[ $1 == '' ]]; then
    get_kube_version
else
    get_kube_version $1
fi

common_prepare
echo "### 安装 kubeadm kubelet kubectl"
install_kube &>>/tmp/kubeabc.log
echo "### 初始化 kubernetes ${KUBE_VERSION}"
kube_init_one_node &>>/tmp/kubeabc.log
echo "### 安装 flannel"
install_flannel &>>/tmp/kubeabc.log

echo ""
echo "### 如需添加 node 节点，请到目标机器执行以下命令"
echo ""
echo "curl -s http://${ENDPOINT}/join.sh | bash -s -- ${KUBE_VERSION}"
grep "kubeadm join" -A1 /tmp/kubeabc.log
echo ""
echo "### 如遇到问题需要清理节点，请执行以下命令"
echo "curl -s http://${ENDPOINT}/cleanup.sh | bash -s"
