begin;
create function add_prow_deck_jobs()
  returns text
  language plpgsql as $$

  declare affected_rows integer;

begin

  create temp table prow_deck_import(
    data jsonb
  );

copy prow_deck_import from program 'curl https://prow.k8s.io/data.js | jq -c .' csv quote e'\x01' delimiter e'\x02';

insert into prow.deck(refs_key, job,build_id,context,started,finished,duration,state,description,url,pod_name,agent,prow_job)
select
  d->>'refs_key',
  d->>'job',
  d->>'build_id',
  d->>'context',
  to_timestamp((d->>'started')::bigint),
  case when (d->>'finished') != ''
    then (d->>'finished')::timestamp
  else null
  end as finished,
  d->>'duration',
  d->>'state',
  d->>'description',
  d->>'url',
  d->>'pod_name',
  d->>'agent',
  d->>'prow_job'
  from prow_deck_import deck,
       jsonb_array_elements(deck.data) d
on conflict do nothing;

get diagnostics affected_rows = ROW_COUNT;

drop table prow_deck_import;

notify prow, 'new jobs added';

return 'Inserted '||affected_rows||' new jobs into prow deck';
  end
  $$;

comment on function add_prow_deck_jobs is 'adds jobs from prow.k8s.io/data.js, ignoring any existing jobs';

commit;
