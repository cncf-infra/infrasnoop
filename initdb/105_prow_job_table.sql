begin;
create table prow.job(
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  repo text,
  head text,
  ref text,
  file text,
  data jsonb
);

comment on table prow.job is 'the yaml and metadata of a prow job';
comment on column prow.job.id is 'Auto generated row id';
comment on column prow.job.repo is 'where this job came from';
comment on column prow.job.head is 'the branch head we used ,e.g. origin/master';
comment on column prow.job.ref is 'commit hash of the clone of the repo at head';
comment on column prow.job.file is 'filepath of this job yaml';
comment on column prow.job.data is 'full job yaml as jsonb';


select 'prow.job table created and commented' as "Build Log";

commit;
