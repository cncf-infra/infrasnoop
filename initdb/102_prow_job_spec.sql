begin;
create table prow.job_spec(
  job text not null,
  build_id text not null unique,
  data jsonb,
  foreign key (job,build_id) references prow.deck(job,build_id),
  primary key (job,build_id)
  );

comment on table  prow.job_spec is 'The job definition for a prow job, taken from its prowjob.yaml';
comment on column prow.job_spec.job is 'The prow job title. May appear multiple times.';
comment on column prow.job_spec.build_id is 'The exact build of this job.';
comment on column prow.job_spec.data is 'the prowjob spec as json';

commit;

select 'prow.job_spec table created and commented' as "Build Log";
