begin;
create temp table sig_raw(data jsonb);
select count(*) from sig_raw;
\copy sig_raw from '/data/sigs.json' csv quote e'\x01' delimiter e'\x02';
select count(*) from sig_raw;
insert into committee(charter_link,contact,dir,label,leadership,meetings,mission_statement,name,subprojects)
            (select c->>'charter_link',
                    c->'contact',
                    c->>'dir',
                    c->>'label',
                    c->'leadership',
                    c->'meetings',
                    c->>'mission_statement',
                    c->>'name',
                    c->'subprojects'
               from sig_raw raw,
                    jsonb_array_elements(raw.data->'committees') c);
drop table sig_raw;
commit;
select 'committees loaded into committee table' as "Build Log",
       count(*) as rows_loaded
  from committee;
