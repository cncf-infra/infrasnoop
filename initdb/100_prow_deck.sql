begin;
create table prow.deck(
  refs_key text,
  job text,
  build_id text unique,
  context text,
  started timestamp,
  finished timestamp,
  duration text,
  state text,
  description text,
  url text,
  pod_name text,
  agent text,
  prow_job text,
  primary key(job, build_id)
);

comment on table prow.deck is 'full logs from prow.k8s.io/data.js';

commit;

select 'prow.deck table created and commented' as "Build Log";
