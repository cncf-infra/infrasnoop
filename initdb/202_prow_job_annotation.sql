begin;
create view prow.job_annotation as
  select job,annotation,content
    from prow.job js,
         jsonb_each(js.data->'metadata'->'annotations') a(annotation,content);

comment on view prow.job_annotation is 'every annotation of a job take from the prowspec of the job';
comment on column prow.job_annotation.job is 'the job these annotations are attached to';
comment on column prow.job_annotation.annotation is 'the key or name of annotation';
comment on column prow.job_annotation.content is 'the value of the annotation key';
commit;

select 'prow.job_annotation view created and commented' as "Build Log";
