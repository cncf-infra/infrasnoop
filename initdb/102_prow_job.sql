begin;
create table prow.job(
  job text not null,
  build_id text not null unique,
  data jsonb,
  foreign key (job,build_id) references prow.deck(job,build_id),
  primary key (job,build_id)
  );

comment on table  prow.job is 'The job definition for a prow job, taken from its prowjob.yaml. Only uses latest successful jobs.';
comment on column prow.job.job is 'The prow job title. May appear multiple times.';
comment on column prow.job.build_id is 'The exact build of this job.';
comment on column prow.job.data is 'the prowjob definition, literally its prowjob.json';

commit;

select 'prow.job table created and commented' as "Build Log";
