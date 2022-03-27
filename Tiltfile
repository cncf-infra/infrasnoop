## -*- mode: python -*-

# Install the postgresql operator
pg_op_installed = str(local('kubectl api-resources | grep postgresqls | wc -l')).strip()
if pg_op_installed == '0':
  local('kubectl -n default apply -k github.com/zalando/postgres-operator/manifests && sleep 3')

# Install the postgres-operator-ui
pg_op_ui_installed = str(local('kubectl -n default get deployments | grep postgres-operator-ui | wc -l')).strip()
if pg_op_ui_installed == '0':
  local('kubectl -n default apply -k github.com/zalando/postgres-operator/ui/manifests')

# Create the namespace
namespace_installed = str(local('kubectl get ns| grep infrasnoop | wc -l')).strip()
if namespace_installed == '0':
  local('kubectl create ns infrasnoop')

# Default to focusing on infrasnoop namespace
local('kubectl config set-context --current --namespace=infrasnoop')

# Create the namespace
sa_key_installed = str(local('kubectl get secret | grep ii-k8s-infra-sa-key | wc -l')).strip()
if sa_key_installed == '0':
  local('kubectl -n infrasnoop create secret generic ii-k8s-infra-sa-key --from-file ii-service-account.json')

k8s_yaml('./manifests/postgresql.yaml')
# k8s_resource(new_name='postgres',
#              objects=['quick-postgres'],
#              extra_pod_selectors=[{'kubedb.com/name': 'quick-postgres'}],
#              port_forwards=5432)
