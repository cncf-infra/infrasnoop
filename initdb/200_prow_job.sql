begin;
create view prow.job as (
  --periodics
  select file,
         p->>'name' as job,
         'periodic' as job_type,
         null as key,
         p as data
    from prow.job_raw raw
         , jsonb_array_elements(raw.data -> 'periodics') p
           union (
             --presubmits
             select file,
                    prejob->>'name' job,
                    'presubmit' as job_type,
                    presubmits.key as key,
                    prejob as data
               from prow.job_raw raw
                    , jsonb_each(raw.data -> 'presubmits') presubmits(key, value)
                    , jsonb_array_elements(presubmits.value) prejob)
           union (
             --postsubmits
             select file,
                    postjob->>'name' job,
                    'postsubmit' as job_type,
                    post.key as key,
                    postjob as data
               from prow.job_raw raw
                    , jsonb_each(raw.data -> 'postsubmits') post(key, value)
                    , jsonb_array_elements(post.value) postjob)
);

comment on view prow.job is 'the prow job data for each periodic,pressubmit,and postsumbit jobs';

commit;
