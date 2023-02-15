begin;
create table cs.job(
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  url text,
  processed timestamp with time zone default current_timestamp,
  duration int,
  files_opened int
);

comment on table cs.job is 'metadata for code search query(the job)';
comment on column cs.job.id is 'auto generated id for this job';
comment on column cs.job.url is 'the full url of the query';
comment on column cs.job.processed is 'auto generated timestamp of when this job(the query and response) was run';
comment on column cs.job.duration is 'length it took to generate response, as provided in response';
comment on column cs.job.files_opened is 'how many files were involved in search, as provided in response';

select 'cs.job table created and commented' as "Build Log";

commit;
