export REGISTRY_DATA='/data/registry'
export REGISTRY_URL='https://xxx.xxx.xxx'
export USERNAME='asdf'
export PASSWORD='asdffdsa'

install_registry() {
  mkdir -p ${REGISTRY_DATA}
  cat <<EOF >>${REGISTRY_DATA}/config.yaml
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
    -v ${REGISTRY_DATA}/data/:/var/lib/registry/ \
    -v ${REGISTRY_DATA}/config.yaml:/etc/docker/registry/config.yml \
    registry:v2.7.1
}

install_registry_with_proxy() {
  mkdir -p ${REGISTRY_DATA}
  cat <<EOF >>${REGISTRY_DATA}/config.yaml
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
proxy:
  remoteurl: ${REGISTRY_URL}
  username: ${USERNAME}
  password: ${PASSWORD}
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
    -v ${REGISTRY_DATA}/data/:/var/lib/registry/ \
    -v ${REGISTRY_DATA}/config.yaml:/etc/docker/registry/config.yml \
    registry:v2.7.1
}
