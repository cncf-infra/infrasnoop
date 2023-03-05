begin;
create temporary table job_artifact_import(url text);

\copy job_artifact_import from '../data/storage_urls.txt';

insert into prow.artifact(job,build_id,url)
select
  regexp_substr(url,'(?<=https://storage.googleapis.com/kubernetes-jenkins/logs/)[a-zA-Z0-9-]*(?=/)') as job,
  regexp_substr(url,'(?<=https://storage.googleapis.com/kubernetes-jenkins/logs/.*/)[0-9]*(?=/)') as build_id,
  url as url
  from job_artifact_import;
drop temporary table job_artifact_import;
commit;
