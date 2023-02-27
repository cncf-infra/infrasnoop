begin;
create table prow.deck(
  id uuid not null default gen_random_uuid() primary key,
  refs_key text,
  job text,
  build_id text,
  context text,
  started timestamp,
  finished timestamp,
  duration text,
  state text,
  description text,
  url text,
  pod_name text,
  agent text,
  prow_job text
);
comment on table prow.deck is 'full logs from prow.k8s.io/data.js';
comment on column prow.deck.id is 'Auto generated row id';

commit;

select 'prow.deck table created and commented' as "Build Log";
