#!/bin/bash

set -e

# echo "HELLO FROM STARTUP SCRIPT"
# curl "https://raw.githubusercontent.com/kubernetes/community/master/sigs.yaml" | yq -o "json" . | jq -c . > /data/sigs.json

cd /data
# folder="test-infra"
# repo="https://github.com/kubernetes/test-infra"
# if ! git clone "${repo}" "${folder}" 2>/dev/null && [ -d "${folder}" ] ; then
#     echo "Clone of ${repo} failed because the folder ${folder} exists"
# fi

# bb prowfetch.clj
tree -L 1 /data
