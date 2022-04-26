export ENDPOINT="CHANGEME"
export PODSUBNET="10.244.0.0/16"
export SVCSUBNET="10.96.0.0/12"

source <(curl -s ${ENDPOINT}/1-function.sh)

rm -rf /tmp/kubeadc.log

get_kube_version $1

common_prepare
kube_init_one_node $1
install_flannel

echo ""
echo "### 如需添加 node 节点，请到目标机器执行以下命令"
echo ""
echo "curl -s http://${ENDPOINT}/join.sh | bash -s -- ${KUBE_VERSION}"
grep "kubeadm join" -A1 /tmp/kubeabc.log | sed 's/\\//g' | sed ":a;N;s/\n//g;ta" | sed "s|--token|  --node-name \$(cat /tmp/ownip)  --token |g"
echo ""
echo "### 如遇到问题需要清理节点，请执行以下命令"
echo "curl -s http://${ENDPOINT}/cleanup.sh | bash -s"
