begin;
create or replace view prow.latest_success as
select job,build_id,url
  from
    (select distinct on (job) *
       from prow.deck
      where state = 'success'
      order by job, finished) as latest_success;

comment on view prow.latest_success is 'The most recent successful build of each job in prow.deck';
commit;
