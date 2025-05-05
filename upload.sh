docker cp 10-mist-cni.conf kind-control-plane:/etc/cni/net.d/
docker cp mist-cni kind-control-plane:/opt/cni/bin/
docker cp tracing-bin kind-control-plane:/usr/local/bin/tracing
