## -*- mode: python -*-
allow_k8s_contexts('kubernetes-admin@bobymcbobs')
load('ext://ko', 'ko_build')
k8s_kind('postgresql', image_json_path='{.spec.initContainers[].image}')

ko_build('ko-local/infrasnoop',
         '.',
         deps=['./main.go', './go.mod', './go.sum'],
         live_update=[])

k8s_yaml('./manifests/namespaces.yaml')
k8s_yaml(local('curl -L -s https://github.com/zalando/postgres-operator/raw/master/charts/postgres-operator/crds/operatorconfigurations.yaml'))
k8s_yaml(local('helm template postgres-operator -n postgres-operator https://raw.githubusercontent.com/zalando/postgres-operator/master/charts/postgres-operator/postgres-operator-1.7.1.tgz'))
k8s_yaml('./manifests/postgresql.yaml')

