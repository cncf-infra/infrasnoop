begin;

create temporary table prow_deck_import(data jsonb);
\copy prow_deck_import from '/data/prow-deck.json' csv quote e'\x01' delimiter e'\x02';

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
       jsonb_array_elements(deck.data) d;
drop table prow_deck_import;
commit;

select 'prow deck loaded into prow.deck table' as "build log",
       count(*) as "rows loaded"
  from prow.deck;
