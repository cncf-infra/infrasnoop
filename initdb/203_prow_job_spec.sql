begin;
create view prow.job_spec as
  select
    job,
    data->'spec'->'refs' as refs,
    data->'spec'->'type' as type,
    data->'spec'->'agent' as agent,
    data->'spec'->'report' as report,
    data->'spec'->'cluster' as cluster,
    data->'spec'->'context' as context,
    data->'spec'->'pod_spec' as pod_spec,
    data->'spec'->'namespace' as namespace,
    data->'spec'->'rerun_command' as rerun_command,
    data->'spec'->'prowjob_defaults' as prowjob_defaults,
    data->'spec'->'decoration_config' as decoration_config
    from prow.job;

comment on view prow.job_spec is 'the spec from a prowjob.json expanded into sql columns';

commit;


select 'prow.job_spec view created and commented' as "Build Log";
