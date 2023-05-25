begin;

create table prow.artifact(
  job text,
  build_id text,
  url text unique not null primary key,
  size text,
  modified text,
  data text,
  filetype text,
  foreign key (job,build_id) references prow.deck(job,build_id) on delete cascade
);

comment on table  prow.artifact is 'every artifact link for the most recent successful prow jobs';
comment on column prow.artifact.job is 'job this artifact applies to';
comment on column prow.artifact.build_id is 'id of specific running of this job';
comment on column prow.artifact.url is 'url of artifact';
comment on column prow.artifact.size is 'size in bytes of artifact';
comment on column prow.artifact.modified is 'last modified date of artifact';
comment on column prow.artifact.data  is 'the text blob of this file. Can be null until it is fetched';
comment on column prow.artifact.filetype is 'is it json,yaml, or text';

commit;

select 'prow.artifact table created and commented' as "Build Log";
