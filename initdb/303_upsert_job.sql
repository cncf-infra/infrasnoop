begin;
create procedure upsertJob(_job text, _build_id text, _data text)
language SQL
as $BODY$
    insert into prow.job(job,build_id,data)
    values(_job, _build_id, _data::jsonb)
  on conflict(job,build_id)
  do
  update set data = _data::jsonb;
$BODY$;

comment on procedure upsertJob is 'Inserts or updates row, based on job+build_id, with the given data';
commit;

select 'upsertJob procedure created and commented' as "Build Log";
