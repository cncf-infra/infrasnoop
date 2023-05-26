begin;

create or replace function describe_relations(
  out schema text,
  out name text,
  out description text
)
  returns setof record
as $$
  select table_schema::text as schema,
  table_name::text as name,
  obj_description(table_name::regclass) as description
  from information_schema.tables
  where table_schema = 'public'
  union
  select table_schema as schema,
  table_name as name,
  obj_description(table_name::regclass) as description
  from information_schema.views
  where table_schema = 'public'
  union
  select  table_schema as schema,
  table_name as name,
  obj_description(('prow.'||table_name)::regclass) as description
  from information_schema.views
  where table_schema = 'prow'
  union
  select  table_schema as schema,
  table_name as name,
  obj_description(('sigs.'||table_name)::regclass) as description
  from information_schema.tables
  where table_schema = 'sigs'
  group by name, table_schema
  order by schema desc, name;
  $$ language SQL;

comment on function describe_relations is 'lists all tables and views in db and short description for each';

commit;
select 'describe_relations function defined and commented' as "build log";
