mkdir -p /data/registry

cat <<EOF >>/data/registry/config.yaml
version: 0.1
log:
  level: info
  fields:
    service: registry
    environment: development
storage:
    delete:
      enabled: true
    cache:
        blobdescriptor: ""
    filesystem:
        rootdirectory: /var/lib/registry
    maintenance:
        uploadpurging:
            enabled: false
http:
    addr: :60080
    debug:
        addr: :5001
        prometheus:
            enabled: true
            path: /metrics
    headers:
        X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: false
EOF

docker run -d \
    --name registry \
    --network host \
    --restart always \
    -v /data/registry/registry/:/var/lib/registry/ \
    -v /data/registry/config.yaml:/etc/docker/registry/config.yml \
    registry:v2.7.1
