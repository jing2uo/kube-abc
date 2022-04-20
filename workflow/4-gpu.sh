
cat << EOF >> /tmp/gpu.yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: tke-admin
rules:
- apiGroups:
  - '*'
  resources:
  - '*'
  verbs:
  - '*'
- nonResourceURLs:
  - '*'
  verbs:
  - '*'
 
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tke-admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: tke-admin
subjects:
- kind: ServiceAccount
  name: tke-admin
  namespace: kube-system
 
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tke-admin
  namespace: kube-system  
---
apiVersion: v1
data:
  gpu-quota-admission.config: |
   {
        "QuotaConfigMapName": "gpuquota",
        "QuotaConfigMapNamespace": "kube-system",
        "GPUModelLabel": "gaia.tencent.com/gpu-model",
        "GPUPoolLabel": "gaia.tencent.com/gpu-pool"
    }
kind: ConfigMap
metadata:
  name: gpu-quota-admission
  namespace: kube-system
---
apiVersion: v1
data:
  nvidia.conf: |-
    /usr/local/host/lib/nvidia-410
    /usr/local/host/lib64/nvidia
    /usr/local/host/local/nvidia/lib64
    /usr/local/host/lib64
    /usr/local/lib64
kind: ConfigMap
metadata:
  name: gpu
  namespace: kube-system
---
apiVersion: extensions/v1beta1
kind: DaemonSet
metadata:
  namespace: kube-system
  name: gpu-manager-daemonset
spec:
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      # This annotation is deprecated. Kept here for backward compatibility
      # See https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/
      annotations:
        scheduler.alpha.kubernetes.io/critical-pod: ""
      labels:
        name: gpu-manager-ds
    spec:
      serviceAccount: tke-admin
      tolerations:
      - operator: Exists
      # Mark this pod as a critical add-on; when enabled, the critical add-on
      # scheduler reserves resources for critical add-on pods so that they can
      # be rescheduled after a failure.
      # See https://kubernetes.io/docs/tasks/administer-cluster/guaranteed-scheduling-critical-addon-pods/
      priorityClassName: "system-node-critical"
      # only run node hash gpu device
      nodeSelector:
        nvidia-device-enable: enable
      hostPID: true
      containers:
        - image: ccr.ccs.tencentyun.com/tkeimages/gpu-manager:latest
          imagePullPolicy: IfNotPresent
          name: gpu-manager
          imagePullPolicy: Always
          securityContext:
            privileged: true
          ports:
            - containerPort: 5678
          volumeMounts:
            - name: device-plugin
              mountPath: /var/lib/kubelet/device-plugins
            - name: vdriver
              mountPath: /etc/gpu-manager/vdriver
            - name: vmdata
              mountPath: /etc/gpu-manager/vm
            - name: log
              mountPath: /var/log/gpu-manager
            - name: docker
              mountPath: /var/run/docker.sock
              readOnly: true
            - name: cgroup
              mountPath: /sys/fs/cgroup
              readOnly: true
            - name: usr-directory
              mountPath: /usr/local/host
              readOnly: true
            - mountPath: /etc/ld.so.conf.d/nvidia.conf
              name: configmap-gpu
              subPath: nvidia.conf
          env:
            - name: EXTRA_FLAGS
              value: --incluster-mode=true
            - name: LOG_LEVEL
              value: "4"
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
      volumes:
        - name: device-plugin
          hostPath:
            type: Directory
            path: /var/lib/kubelet/device-plugins
        - name: vmdata
          hostPath:
            type: DirectoryOrCreate
            path: /etc/gpu-manager/vm
        - name: vdriver
          hostPath:
            type: DirectoryOrCreate
            path: /etc/gpu-manager/vdriver
        - name: log
          hostPath:
            type: DirectoryOrCreate
            path: /etc/gpu-manager/log
        - name: docker
          hostPath:
            type: File
            path: /var/run/docker.sock
        - name: cgroup
          hostPath:
            type: Directory
            path: /sys/fs/cgroup
        # We have to mount /usr directory instead of specified library path, because of non-existing
        # problem for different distro
        - name: usr-directory
          hostPath:
            type: Directory
            path: /usr
        - configMap:
            defaultMode: 420
            name: gpu
          name: configmap-gpu
EOF

kubectl apply -f /tmp/gpu.yaml