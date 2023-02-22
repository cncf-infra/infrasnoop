begin;

create temp table prow_job_raw(data jsonb);
\copy prow_job_raw from '/data/prow-jobs.json' csv quote e'\x01' delimiter e'\x02';

insert into prow.job(repo,head,ref,file,data)
            (select p->>'repo',
                    p->>'head',
                    p->>'ref',
                    p->>'file',
                    p->'data'
               from prow_job_raw raw,
                    jsonb_array_elements(raw.data) p);
drop table prow_job_raw;

commit;

select 'jobs loaded into prow.job table' as "build log",
       count(*) as "rows loaded"
  from prow.job;
