(ns prowfetch
  (:require [clojure.string :as str]
            [clojure.java.io :as io]
            [org.httpkit.client :as http]
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

(defn url->log-url [url]
  (let [new-url (str/replace url #"prow.k8s.io/view/gs" "storage.googleapis.com")]
    (str new-url
         (when (not (str/ends-with? new-url "/")) "/")
         "build-log.txt")))


(def sampleten
  (take 100
        (map #(assoc % :url (url->log-url (:url %)))
             (map #(select-keys % [:job :build_id :url]) (filter #(= "success" (:state %)) (json/parse-string (slurp "prow-deck.json") true))))))

(defn add-text
  [job]
  (try
    (let [text (:body (curl/get (:url job)))]
      (assoc job :text text))
    (catch Exception e
      (assoc job :text (str "ERROR: " e)))))


(spit "test-log.json"
      (json/generate-string
       (pmap add-text sampleten)))
