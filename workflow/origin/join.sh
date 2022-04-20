export ENDPOINT="CHANGEME"

source <(curl -s ${ENDPOINT}/1-function.sh)

common_prepare
echo "### 安装 kubeadm kubelet kubectl"
get_kube_version $1
install_kube &>>/tmp/inkube.log
echo ""
echo "### 如遇到问题需要清理节点，请执行以下命令"
echo "curl -s http://${ENDPOINT}/cleanup.sh | bash -s"
