begin;
create table prow.job_raw(
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  repo text,
  head text,
  ref text,
  file text,
  data jsonb
);

comment on table prow.job_raw is 'the yaml and metadata of a prow job';
comment on column prow.job_raw.id is 'Auto generated row id';
comment on column prow.job_raw.repo is 'where this job came from';
comment on column prow.job_raw.head is 'the branch head we used ,e.g. origin/master';
comment on column prow.job_raw.ref is 'commit hash of the clone of the repo at head';
comment on column prow.job_raw.file is 'filepath of this job yaml';
comment on column prow.job_raw.data is 'full job yaml as jsonb';


select 'prow.job_raw table created and commented' as "Build Log";

commit;
