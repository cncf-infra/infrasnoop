begin;
create temp table sig_raw(data jsonb);
\copy sig_raw from './data/sigs.json' csv quote e'\x01' delimiter e'\x02';
insert into sig(charter_link,contact,dir,label,leadership,meetings,mission_statement,name,subprojects)
            (select s->>'charter_link',
                    s->'contact',
                    s->>'dir',
                    s->>'label',
                    s->'leadership',
                    s->'meetings',
                    s->>'mission_statement',
                    s->>'name',
                    s->'subprojects'
               from sig_raw raw,
                    jsonb_array_elements(raw.data->'sigs') s);

drop table sig_raw;
commit;
select 'sigs loaded into sig table' as "build log",
       count(*) as "rows loaded"
  from sig;
