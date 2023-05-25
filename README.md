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

## Our data

At the moment, we have tables setup in two schemas: **prow** and **sigs**. Prow deals with data taken from prow.k8s.io and individual prow jobs.  Sigs is a sql representation of the kubernetes sigs.yaml.

There will be no data from the start.   To load prow, run:

``` sql
select * from add_prow_deck_jobs();
```
This will load in every line of job metadtaa found at https://prow.k8s.io/
(about 19,000 rows)

In the background, our sideloader app will fetch the prowspec for all the latest
successful jobs (about 1,900).

To load up sigs, you can run:

``` sql
select * from load_sigs_tables();
```


## Learning more

We have a couple helper functions to learn the db better.  

``` sql
select * from describe_relations();
```

will list the relations and their comments across all schemas.

You can also run

``` sql
select * from describe_relation('schema','relation');
```

for the comment on a specific one.

Similarly, to learn about the columns, you can run

``` sql
select * from describe_columns('schema','relation');
```

Though this is basically equivalent to running ~\d schema.relation~ in psql.
