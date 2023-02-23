(ns prowfetch
  (:require [clojure.string :as str]
            [clojure.java.io :as io]
            [babashka.fs :as fs]
            [cheshire.core :as json]
            [clj-yaml.core :as yaml]
            [babashka.curl :as curl]))

(def ref-branch
  (-> "./test-infra/.git/packed-refs"
      slurp
      str/split-lines
      second
      (str/split #" ")))

(defn yamls->json
  [files]
  (map
   #(json/generate-string
    (assoc {}
           :repo "kubernetes/test-infra"
           :head (second ref-branch)
           :ref (first ref-branch)
           :file %
           :data (yaml/parse-string (slurp %))))
   files))

(defn files->json
  [path glob outfile]
  (->> (fs/glob path glob)
       (map str)
       yamls->json
       (str/join ",")
       (format "[%s]")
       (spit outfile)))

(files->json "./test-infra/config/jobs/" "**.yaml" "prow-jobs.json")
(files->json "./test-infra/" "**OWNERS" "owners.json")
(spit "prow-deck.json" (:body (curl/get "https://prow.k8s.io/data.js")))
