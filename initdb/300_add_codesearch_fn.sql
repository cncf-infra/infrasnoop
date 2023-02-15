begin;
create function add_codesearch(search_url text)
  returns table (id uuid,
                 search text,
                 processed timestamp with time zone,
                 duration integer,
                 files_opened integer,
                 result_rows bigint)
  language plpgsql as $$

  declare job_id uuid;
begin

  create temp table cs_raw(
    data jsonb
  );

EXECUTE format($url$ COPY cs_raw
               from program 'curl "%s" | jq -c .' csv quote e'\x01' delimiter e'\x02'$url$,
               search_url);

insert into cs.job(url,duration,files_opened)
            (select
               search_url,
               cast(raw.data->'Stats'->>'Duration' as int),
               cast(raw.data->'Stats'->>'FilesOpened' as int)
               from cs_raw raw);

select job.id into job_id from cs.job where job.url = search_url;

insert into cs.result(job_id,repo,filename,linenumber,line,before,after)
            (select
               job_id,
               repo,
               matches->'Filename',
               file_match->>'LineNumber',
               file_match->>'Line',
               file_match->'Before',
               file_match->'After'
               from cs_raw raw
                    , jsonb_each((raw.data -> 'Results')) results(repo, value)
                    , jsonb_array_elements(value->'Matches') matches
                    , jsonb_array_elements(matches->'Matches') file_match);

return query
  select job.id,
  search_url,
  job.processed,
  job.duration,
  job.files_opened,
  count(*) as match_count
  from cs.job job
  join cs.result on(job.id = result.job_id)
  group by job.id,search_url,job.processed,job.duration,job.files_opened;

drop table cs_raw;

end
$$;

comment on function add_codesearch is 'Takes a url with a cs.k8s.io api call and populates cs.job and cs.result with the api response';

commit;
