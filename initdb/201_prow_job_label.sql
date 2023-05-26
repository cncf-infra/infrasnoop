begin;
create view prow.job_label as
  select job,label,content
    from prow.job js,
         jsonb_each_text(js.data->'metadata'->'labels') l(label,content);

comment on view prow.job_label is 'every label of a job take from the prowspec of the job';
comment on column prow.job_label.job is 'the job these labels are attached to';
comment on column prow.job_label.label is 'the key or name of label';
comment on column prow.job_label.content is 'the value of the label key';

commit;

select 'prow.job_label view created and commented' as "Build Log";
