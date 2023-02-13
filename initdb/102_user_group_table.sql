begin;
create table user_group (
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
commit;
select 'Created user_group table' as "Build Log";
