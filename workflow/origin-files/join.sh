export ENDPOINT="CHANGEME"

source <(curl -s ${ENDPOINT}/1-function.sh)

rm -rf /tmp/kubeadc.log
common_prepare
install_kube $1

echo ""
echo "### 如遇到问题需要清理节点，请执行以下命令"
echo "curl -s http://${ENDPOINT}/cleanup.sh | bash -s"
