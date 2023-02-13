#!/bin/bash

set -e

echo "HELLO FROM STARTUP SCRIPT"
tree /data
which jq
curl "https://raw.githubusercontent.com/kubernetes/community/master/sigs.yaml" | yq -o "json" . | jq -c . > /data/sigs.json
