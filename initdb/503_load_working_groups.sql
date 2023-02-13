begin;
create temp table sig_raw(data jsonb);
\copy sig_raw from './data/sigs.json' csv quote e'\x01' delimiter e'\x02';
insert into working_group(charter_link,contact,dir,label,leadership,meetings,mission_statement,name,stakeholder_sigs)
            (select w->>'charter_link',
                    w->'contact',
                    w->>'dir',
                    w->>'label',
                    w->'leadership',
                    w->'meetings',
                    w->>'mission_statement',
                    w->>'name',
                    w->'stakeholder_sigs'
               from sig_raw raw,
                    jsonb_array_elements(raw.data->'workinggroups') w);

drop table sig_raw;
commit;
select 'working groups loaded into working_group table' as "build log",
       count(*) as "rows loaded"
  from working_group;
