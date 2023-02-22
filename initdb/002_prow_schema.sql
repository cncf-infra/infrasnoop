begin;
create schema prow;
comment on schema prow is 'Files related to kubernetes prow';
select 'prow schema created' as "Build Log";
commit;
