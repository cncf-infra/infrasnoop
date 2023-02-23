begin;

create temp table prow_job_import(data jsonb);
\copy prow_job_import from '/data/prow-jobs.json' csv quote e'\x01' delimiter e'\x02';

insert into prow.job_raw(repo,head,ref,file,data)
            (select p->>'repo',
                    p->>'head',
                    p->>'ref',
                    p->>'file',
                    p->'data'
               from prow_job_import imp,
                    jsonb_array_elements(imp.data) p);

drop table prow_job_import;

commit;

select 'jobs loaded into prow.job_raw table' as "build log",
       count(*) as "rows loaded"
  from prow.job_raw;
