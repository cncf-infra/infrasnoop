## -*- mode: python -*-
secret_settings( disable_scrub = True )
load('ext://ko', 'ko_build')
load('ext://namespace', 'namespace_create','namespace_inject')
namespace_create('infrasnoop')
# in pair:
allow_k8s_contexts('kubernetes-admin@'+os.environ['SHARINGIO_PAIR_NAME'])
# update k8s-infra:postgresql:infrasnoop ko-local/infrasnoop
# it's embedded within the postgresql crd object
ko_build('ko-local/infrasnoop',
         '.',
         deps=['./main.go', './go.mod', './go.sum'],
         live_update=[],
         )
# gcs csi / gs buckets as a mounted volume!
# k8s_yaml(local(
#    'kubectl apply -k https://github.com/ofek/csi-gcs/deploy/overlays/stable --dry-run=client -o yaml'))
# service-account for gcs
k8s_yaml(local(
    'kubectl -n default create secret generic csi-gcs-secret --from-file=key=ii-service-account.json --dry-run=client -o yaml'))

k8s_yaml(namespace_inject(
    read_file('./manifests/csi-gcs/static/sc.yaml'),
    'infrasnoop'))
k8s_yaml(namespace_inject(
    read_file('./manifests/csi-gcs/static/pv.yaml'),
    'infrasnoop'))
k8s_yaml(namespace_inject(
    read_file('./manifests/csi-gcs/static/pvc.yaml'),
    'infrasnoop'))
k8s_yaml(local('kubectl -n infrasnoop create secret generic ii-k8s-infra-sa-key --from-file ii-service-account.json --dry-run=client -o yaml'))
k8s_yaml(namespace_inject(
    read_file('./manifests/postgresql.yaml'),
    'infrasnoop')) # crd creates
k8s_kind('postgresql',
         image_json_path='{.spec.initContainers[*].image}')
