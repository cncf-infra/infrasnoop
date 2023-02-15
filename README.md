# Infrasnoop

An early exploration into mapping work to be done in kubernetes through combining data in sigs.json and cs.k8s.io into a postgres db

# Quick start

```sh
mkdir data # will map to the container's /data
docker build -t infrasnoop:latest .
docker-compose up
```

# Exploring Data

On start, there are four tables populated with data: committee, sig, user_group, working_group.

These are populated by the latest [k8s/community/sigs.yaml](https://github.com/kubernetes/community/blob/master/sigs.yaml)

To see the names of all present sigs, for example, you could run:

``` sql
select name from sig;
```

## Code search
There is also the cs schema with it's tables cs.job and cs.result.  

These are related to running codesearch queries via cs.k8s.io.  The idea is to generate a query, and then put it's results into
these tables so you can query them easily and combine them with the data from the sigs.yaml

There is a helper function for populating the table with a codesearch result.  

If you have a query you've run against the api.  Like, for example, all instances of `k8s.gcr.io`:

```
https://cs.k8s.io/api/v1/search?stats=fosho&repos=*&rng=%3A20&q=k8s.gcr.io&i=nope&files=&excludeFiles=vendor%2F
```

Then you can populate the tables with

``` sql
select * from add_codesearch('https://cs.k8s.io/api/v1/search?stats=fosho&repos=*&rng=%3A20&q=k8s.gcr.io&i=nope&files=&excludeFiles=vendor%2F');
```

which returns the metadata from the job and how many rows are in the result.

``` sql
                   id                  |                                                     search                                                      |           processed           | duration | files_opened | result_rows 
 --------------------------------------+-----------------------------------------------------------------------------------------------------------------+-------------------------------+----------+--------------+-------------
  826a0d6c-50c9-408d-bb7b-068604cfe91c | https://cs.k8s.io/api/v1/search?stats=fosho&repos=*&rng=%3A20&q=k8s.gcr.io&i=nope&files=&excludeFiles=vendor%2F | 2023-02-15 21:46:14.162785+00 |      169 |         2292 |        1995

```

You could then run a query on the result, like just getting the repo, filename, and linenumber:

``` sql
select distinct repo,filename,linenumber from cs.result limit 20;
```

returning:

``` sql
                          repo                          |                                        filename                                        | linenumber 
--------------------------------------------------------+----------------------------------------------------------------------------------------+------------
 kubernetes/examples                                    | "staging/explorer/Makefile"                                                            | 27
 kubernetes/kube-state-metrics                          | "CHANGELOG.md"                                                                         | 179
 kubernetes/kubernetes                                  | "CHANGELOG/CHANGELOG-1.24.md"                                                          | 2807
 kubernetes-sigs/lwkd                                   | "_posts/2020-06-07-update.md"                                                          | 12
 kubernetes/minikube                                    | "pkg/addons/addons.go"                                                                 | 384
 kubernetes/kops                                        | "docs/releases/1.9-NOTES.md"                                                           | 234
 kubernetes/website                                     | "content/es/docs/concepts/overview/working-with-objects/labels.md"                     | 98
 kubernetes-sigs/sig-storage-local-static-provisioner   | "helm/generated_examples/helm2/baremetal.yaml"                                         | 204
 kubernetes/perf-tests                                  | "clusterloader2/pkg/prometheus/manifests/exporters/kube-state-metrics/deployment.yaml" | 21
 kubernetes-sigs/cluster-api                            | "controlplane/kubeadm/internal/workload_cluster_coredns_test.go"                       | 323
 kubernetes/website                                     | "content/en/blog/_posts/2022-11-28-registry-k8s-io-change.md"                          | 60
 kubernetes/kube-state-metrics                          | "internal/store/pod_test.go"                                                           | 225
 kubernetes-sigs/cluster-api                            | "controlplane/kubeadm/internal/workload_cluster_coredns_test.go"                       | 1233
 kubernetes-sigs/gcp-compute-persistent-disk-csi-driver | "CHANGELOG/CHANGELOG-1.1.md"                                                           | 17
 kubernetes/cloud-provider-vsphere                      | "docs/book/tutorials/kubernetes-on-vsphere-with-kubeadm.md"                            | 51
 kubernetes/node-problem-detector                       | "docs/release_process.md"                                                              | 39
 kubernetes/release                                     | "dependencies.yaml"                                                                    | 189
 kubernetes/ingress-nginx                               | "Changelog.md"                                                                         | 1096
 kubernetes/cloud-provider-vsphere                      | "docs/book/tutorials/k8s-vcp-on-vsphere-with-kubeadm.md"                               | 204
 kubernetes-client/go                                   | "kubernetes/client/v1_container_image.go"                                              | 15
(20 rows)
```
