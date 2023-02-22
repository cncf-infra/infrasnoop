begin;
create table prow.owners(
  id uuid NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  repo text,
  head text,
  ref text,
  file text,
  data jsonb
);

comment on table prow.owners is 'the yaml and metadata of all OWNERS files in a repo';
comment on column prow.owners.id is 'Auto generated row id';
comment on column prow.owners.repo is 'repo where this owners file came from';
comment on column prow.owners.head is 'the branch head we used ,e.g. origin/master';
comment on column prow.owners.ref is 'commit hash of the clone of the repo at head';
comment on column prow.owners.file is 'filepath of this owners file';
comment on column prow.owners.data is 'full owners file as jsonb';

select 'prow.owners table created and commented' as "Build Log";

commit;
