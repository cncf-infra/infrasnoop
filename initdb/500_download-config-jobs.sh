#!/usr/bin/env bash

git clone -v --depth 1 https://github.com/kubernetes/test-infra.git /tmp/src-test-infra
ls -alh /tmp/{,src-test-infra/{config/jobs,}}
