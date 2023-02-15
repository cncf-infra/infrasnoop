begin;
create schema cs;
comment on schema cs is 'Code Search schema. Tables and views related to the results of cs.k8s.io queries';
select 'cs schema created' as "Build Log";
commit;
