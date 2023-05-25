begin;
create function load_sigs_tables()
  returns text
  language plpgsql as $$

  declare affected_rows integer;

begin

create temp table sig_raw(data jsonb);

copy sig_raw from program 'curl https://raw.githubusercontent.com/kubernetes/community/master/sigs.yaml | yq -o "json" . | jq -c' csv quote e'\x01' delimiter e'\x02';

insert into sigs.committee(charter_link,contact,dir,label,leadership,meetings,mission_statement,name,subprojects)
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
                    jsonb_array_elements(raw.data->'committees') c)
            on conflict do nothing;

insert into sigs.sig(charter_link,contact,dir,label,leadership,meetings,mission_statement,name,subprojects)
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
                    jsonb_array_elements(raw.data->'sigs') s)
            on conflict do nothing;

insert into sigs.user_group(charter_link,contact,dir,label,leadership,meetings,mission_statement,name,subprojects)
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
                    jsonb_array_elements(raw.data->'usergroups') u)
            on conflict do nothing;

insert into sigs.working_group(charter_link,contact,dir,label,leadership,meetings,mission_statement,name,stakeholder_sigs)
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
                    jsonb_array_elements(raw.data->'workinggroups') w)
            on conflict do nothing;

drop table sig_raw;

return 'populated, from sigs.yaml, the following tables: sigs.committee, sigs.sig, sigs.usergroup, sigs.raw';
end
$$;

comment on function load_sigs_tables is 'populates each table in sigs schema with corresponding key from sigs.yaml';

commit;
