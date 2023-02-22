begin;
create temp table prow_owners_raw(data jsonb);
\copy prow_owners_raw from '/data/owners.json' csv quote e'\x01' delimiter e'\x02';

insert into prow.owners(repo,head,ref,file,data)
            (select p->>'repo',
                    p->>'head',
                    p->>'ref',
                    p->>'file',
                    p->'data'
               from prow_owners_raw raw,
                    jsonb_array_elements(raw.data) p);
drop table prow_owners_raw;

commit;

select 'owners loaded into prow.owners table' as "build log",
       count(*) as "rows loaded"
  from prow.owners;
