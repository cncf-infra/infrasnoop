begin;

create temporary table prow_artifact_import(data jsonb);

\copy prow_artifact_import from '/data/job-logs.json' csv quote e'\x01' delimiter e'\x02';

select count(*) from prow_artifact_import;

insert into prow.artifact(job,build_id,artifact_url,size,modified)
select job->>'job',
       job->>'build_id',
       artifact->>'href',
       artifact->>'size',
       artifact->>'modified'
  from prow_artifact_import import,
       jsonb_array_elements(import.data) job,
       jsonb_array_elements(job->'artifacts') artifact;

drop table prow_artifact_import;

commit;

select 'artifacts loaded into prow.artifact table' as "build log",
       count(*) as "rows loaded"
  from prow.artifact;
