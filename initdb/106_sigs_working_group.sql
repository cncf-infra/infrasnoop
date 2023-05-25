begin;
create table sigs.working_group (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  charter_link text,
  contact jsonb,
  dir text,
  label text,
  leadership jsonb,
  meetings jsonb,
  mission_statement text,
  name text,
  stakeholder_sigs jsonb
  );

comment on table sigs.working_group is 'each working group in the kubernetes sigs.yaml';
commit;
select 'Created sigs.working_group table' as "Build Log";
