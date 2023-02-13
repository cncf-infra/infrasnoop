# Infrasnoop

An early exploration into mapping work to be done in kubernetes through combining data in sigs.json and cs.k8s.io into a postgres db

# Quick start

```sh
mkdir data # will map to the container's /data
docker build -t infrasnoop:latest .
docker-compose up
```

once it is up, you will have four tables taken from the latest sigs.yaml: committee, sig, user_group, working_group

try something like
```sql
select name from sig;
```
