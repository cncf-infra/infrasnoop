#!/bin/env python

# Tiltfile
#   a fast development flow for APISnoop

namespace = 'infrasnoop'
containerRepoSnoopDB = 'gcr.io/k8s-staging-apisnoop/infrasnoop'

snoopDBYaml = helm(
  'chart',
  name='infrasnoop',
  namespace=namespace,
  set=[]
  )
k8s_yaml(snoopDBYaml)

k8s_resource(workload='infrasnoop-infradb', port_forwards=5432)

if os.getenv('SHARINGIO_PAIR_NAME'):
    allow_k8s_contexts('kubernetes-admin@' + os.getenv('SHARINGIO_PAIR_NAME'))
    custom_build(containerRepoSnoopDB, 'docker build -f Dockerfile -t $EXPECTED_REF .', ['.'], disable_push=True)
else:
    docker_build(containerRepoSnoopDB, '.', dockerfile="Dockerfile")

allow_k8s_contexts('in-cluster')
