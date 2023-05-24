begin;
create procedure upsertJobSpec(_job text, _build_id text, _data text)
language SQL
as $BODY$
    insert into prow.job_spec(job,build_id,data)
    values(_job, _build_id, _data::jsonb)
  on conflict(job,build_id)
  do
  update set data = _data::jsonb;
$BODY$;

comment on procedure upsertJobSpec is 'Inserts or updates row, based on job+build_id, with the given data';
commit;

select 'upsertJobSpec procedure created and commented' as "Build Log";
