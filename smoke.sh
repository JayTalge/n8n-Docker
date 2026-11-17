#!/bin/bash
# Smoke test: usage smoke.sh <image> <n8n version> <overlay node version>
set -euo pipefail
IMG=$1 VERSION=$2 NODE=$3

docker run -d --name smoke -p 5678:5678 -e N8N_DIAGNOSTICS_ENABLED=false "$IMG"
trap 'docker logs --tail 50 smoke; docker rm -f smoke >/dev/null' EXIT

for i in $(seq 1 90); do
  curl -fsS -o /dev/null http://127.0.0.1:5678/healthz && break
  [ "$i" = 90 ] && { echo "n8n did not become healthy"; exit 1; }
  sleep 2
done
echo "healthz ok"

got=$(docker exec smoke n8n --version)
[ "$got" = "$VERSION" ] || { echo "n8n version $got != $VERSION"; exit 1; }

docker exec smoke cat /etc/node-overlay
node=$(docker exec smoke node -v)
[ "$(printf '%s\n%s\n' "v$NODE" "$node" | sort -V | head -1)" = "v$NODE" ] || { echo "node $node older than v$NODE"; exit 1; }
echo "n8n $got, node $node"
