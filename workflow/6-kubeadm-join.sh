export VIPAPISERVER="192.168.137.248:6443"



export CACERTHASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')
export TOKEN=$(kubeadm token list | grep system | awk '{print $1}')
export CERTKEY=$(kubeadm init phase upload-certs --upload-certs | sed -n '$p')

echo "添加 master 节点执行"
echo "kubeadm join ${VIPAPISERVER} --token ${TOKEN} --discovery-token-ca-cert-hash sha256:${CACERTHASH} --control-plane --certificate-key ${CERTKEY}"

echo "添加 node 节点执行"
echo "kubeadm join ${VIPAPISERVER} --token ${TOKEN} --discovery-token-ca-cert-hash sha256:${CACERTHASH} "
