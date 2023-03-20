(ns sideloader.db.core
  (:require
   [hugsql.core :as hug]))

;;-------
;; The DB
;;-------
(def conn
  {:dbtype "postgres"
   :dbname "postgres"
   :host "localhost"
   :user "postgres"
   :password "infra"})

(hug/def-db-fns "sideloader/db/queries.sql")
