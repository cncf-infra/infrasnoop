# Infrasnoop

An early exploration into mapping work to be done in kubernetes through combining data in sigs.json and cs.k8s.io into a postgres db
# Quick start

You can run the db with docker-compose. This'll start up our postgres database anda  side app used to fetch and load json as needed.

``` sh
cp .env.template .env # adjusting as you please
docker-compose build
docker-compose up
```

This will, by default, start up a db accessible at localhost:5432. 

When it is up and running, you can load in all the prow job metadata with:

``` sql
select * from add_prow_deck_jobs();
```

This will load in every line of job metadtaa found at https://prow.k8s.io/
(about 19,000 rows)

In the background, our sideloader app will fetch the prowspec for all the latest
successful jobs (about 1,900).

You can then explore the data using postgres's fun operators.  For example

``` sql
select data->'metadata'->'labels'
from prow.job_spec
where data->'metadata'->'labels'?'dind-enabled';
```

**NOTE:** this db is a bit rough at the moment, and there will be more customized, easier to use views coming.
