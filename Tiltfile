## -*- mode: python -*-
load('ext://ko', 'ko_build')
load('ext://namespace', 'namespace_create','namespace_inject')
namespace_create('infrasnoop')
# In pair:
allow_k8s_contexts('kubernetes-admin@'+os.environ['SHARINGIO_PAIR_NAME'])
# Update k8s-infra:postgresql:infrasnoop ko-local/infrasnoop
# it's embedded within the postgresql crd object
k8s_kind('postgresql',
         image_json_path='{.spec.initContainers[*].image}')
ko_build('ko-local/infrasnoop',
         '.',
         deps=['./main.go', './go.mod', './go.sum'],
         live_update=[],
         )

k8s_yaml(namespace_inject(
    read_file('./manifests/postgresql.yaml'),
    'infrasnoop')) # CRD CReates
k8s_yaml(namespace_inject(
    local('kubectl -n infrasnoop create secret generic ii-k8s-infra-sa-key --from-file ii-service-account.json --dry-run=client -o yaml'),
    'infrasnoop'))
