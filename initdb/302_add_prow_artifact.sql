begin;
create or replace function add_prow_artifact(
  job text,
  build_id text,
  url text,
  size text,
  modified text,
  filetype text
)
  returns text
  language plpgsql as $$
  #variable_conflict use_column

begin
  insert into prow.artifact(
    job,
    build_id,
    url,
    size,
    modified,
    filetype)

  values(
    job,
    build_id,
    url,
    size,
    modified,
    filetype)
    on conflict(url) do nothing;

  return 'Added '||job||'/'||build_id'. Data still needed.';
end;
$$;

comment on function add_prow_artifact is 'adds new row to artifact, sans the data row. We expect to update this data separately.';
commit;
