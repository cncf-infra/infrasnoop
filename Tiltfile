## -*- mode: python -*-
allow_k8s_contexts('kubernetes-admin@bobymcbobs')
load('ext://ko', 'ko_build')
k8s_kind('postgresql', image_json_path='{.spec.initContainers[].image}')

ko_build('ko-local/infrasnoop',
         '.',
         deps=['./main.go', './go.mod', './go.sum'],
         live_update=[],
         )

k8s_yaml('./manifests/namespaces.yaml')
k8s_yaml(local('curl -L -s https://github.com/zalando/postgres-operator/raw/master/charts/postgres-operator/crds/operatorconfigurations.yaml'))
k8s_yaml(local('helm template postgres-operator -n postgres-operator https://raw.githubusercontent.com/zalando/postgres-operator/master/charts/postgres-operator/postgres-operator-1.7.1.tgz'))
k8s_yaml(local('kubectl -n infrasnoop create secret generic ii-k8s-infra-sa-key --from-file ii-service-account.json --dry-run=client -o yaml'))
k8s_resource(workload='postgres-operator',objects=['operatorconfigurations.acid.zalan.do:CustomResourceDefinition:default','postgres-operator:OperatorConfiguration:postgres-operator'])
# Requires that postgresql-operator is actually deployed... not sure if we can delay a bit somehow
k8s_yaml('./manifests/postgresql.yaml')
# Need to run the pod once
k8s_yaml('./manifests/pod.yaml')
