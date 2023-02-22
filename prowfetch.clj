(ns prowfetch
  (:require [clojure.string :as str]
            [babashka.fs :as fs]
            [cheshire.core :as json]
            [clj-yaml.core :as yaml]))

(defn prow->json
  [repo file]
  (json/generate-string
   (assoc {}
          :repo repo
          :file file
          :data (yaml/parse-string (slurp file)))))

(->> (fs/glob "./test-infra/config/jobs" "**.yaml")
    (map str)
    (map prow->json "kubernetes/test-infra")
    (str/join ",")
    (format "[%s]")
    (spit "prow-jobs.json"))
