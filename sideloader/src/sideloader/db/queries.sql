-- src/sideloader/db/queries.sql
-- My Main Functions

-- :name add-prow-deck-jobs :? :1
-- :doc triggers fetch and addition of newest prow deck jobs, returns string detailing # of affected rows
select * from add_prow_deck_jobs();

-- :name get-prow-deck :? :1
-- :doc my query doc to the end of this line
select * from prow.deck;

-- :name latest-successful-jobs :? :*
-- :doc returns the job,build_id, and url for the latest successful run of each job in our prow.deck
select job,build_id,url from prow.latest_success;

-- :name successes_without_artifacts :? :*
-- :doc returns the job,build_id, and url for the latest successful jobs without artifacts.
select job,build_id,url from prow.success_without_artifacts;

-- :name add-prow-artifact :<!
-- :doc add artifact for a job and build_id
select * from add_prow_artifact(:job, :build_id, :url, :size, :modified, :filetype);
