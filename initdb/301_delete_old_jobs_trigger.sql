begin;

create or replace function delete_old_deck_results()
  returns trigger
  language plpgsql
as $$
begin
  delete from prow.deck
   where finished < now() - interval '7 days';
  return new;
end;
$$;

create trigger flush_prow_deck
  after insert or update on prow.deck
  for each statement
    execute procedure delete_old_deck_results();

commit;
