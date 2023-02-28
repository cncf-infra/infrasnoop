begin;

create table prow.artifact(
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  job text,
  build_id text,
  artifact_url text,
  size text,
  modified text
);

comment on table  prow.artifact is 'every artifact link for the most recent successful prow jobs';
comment on column prow.artifact.id is 'auto generated row id';
comment on column prow.artifact.job is 'job this artifact applies to';
comment on column prow.artifact.build_id is 'id of specific running of this job';
comment on column prow.artifact.artifact_url is 'url of artifact';
comment on column prow.artifact.size is 'size in bytes of artifact';
comment on column prow.artifact.modified is 'last modified date of artifact';

commit;

select 'prow.artifact table created and commented' as "Build Log";
