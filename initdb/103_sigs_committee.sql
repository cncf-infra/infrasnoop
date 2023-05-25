begin;
create table sigs.committee (
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  charter_link text,
  contact jsonb,
  dir text,
  label text,
  leadership jsonb,
  meetings jsonb,
  mission_statement text,
  name text,
  subprojects jsonb
  );

comment on table sigs.committee is 'each committee in the kubernetes sigs.yaml';
commit;

select 'Created committee table' as "Build Log";
