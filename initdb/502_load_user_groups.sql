begin;
create temp table sig_raw(data jsonb);
\copy sig_raw from './data/sigs.json' csv quote e'\x01' delimiter e'\x02';

insert into user_group(charter_link,contact,dir,label,leadership,meetings,mission_statement,name,subprojects)
(select u->>'charter_link',
        u->'contact',
        u->>'dir',
        u->>'label',
        u->'leadership',
        u->'meetings',
        u->>'mission_statement',
        u->>'name',
        u->'subprojects'
  from sig_raw raw,
       jsonb_array_elements(raw.data->'usergroups') u);

drop table sig_raw;
commit;
select 'usergroups loaded into user_group table' as "build log",
       count(*) as "rows loaded"
         from user_group;
