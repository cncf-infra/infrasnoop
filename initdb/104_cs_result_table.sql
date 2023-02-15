begin;
create table cs.result (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  job_id uuid references cs.job(id),
  repo text,
  filename text,
  linenumber text,
  line text,
  before jsonb,
  after jsonb
);

comment on table cs.result is 'Formatted Results value of a codesearch response';
comment on column cs.result.id is 'Auto generated row id';
comment on column cs.result.job_id is 'id of the cs.job these results are from.';
comment on column cs.result.repo is 'repo in where match was found';
comment on column cs.result.filename is 'filename where match was found';
comment on column cs.result.linenumber is 'line number of file of match';
comment on column cs.result.line is 'full line where match is found';
comment on column cs.result.before is 'the content of line preceding match';
comment on column cs.result.after is 'the content of line following match';

select 'cs.result table created and commented' as "Build Log";

commit;
