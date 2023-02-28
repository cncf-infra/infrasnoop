(ns prowfetch
  (:require [clojure.string :as str]
            [babashka.pods :as pods]
            [babashka.fs :as fs]
            [cheshire.core :as json]
            [clj-yaml.core :as yaml]
            [babashka.curl :as curl]))

(pods/load-pod "bootleg")
(require '[pod.retrogradeorbit.bootleg.utils :refer [convert-to]]
         '[pod.retrogradeorbit.hickory.select :as s])

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

(defn url->artifact-url [url]
  (let [new-url (str/replace url #"prow.k8s.io/view/gs" "gcsweb.k8s.io/gcs")]
    (if (str/ends-with?  new-url "/")
      new-url
      (str new-url "/"))))

(defn get-artifact-text! [url]
  (try
    (:body (curl/get url))
    (catch Exception e
      (println "error getting artifact text for "url ": " (ex-message e))
      "")))

(defn artifact-text->rows
  [text]
  (let [artifact-soup (-> text
                          str/trim-newline
                          (str/replace #"^\n" "")
                          (convert-to :hickory))]
    (->> artifact-soup
         (s/select (s/descendant (s/class "grid-row")))
         (drop 1))))

(defn row->artifact
  [row]
  (let [[href size modified] (->> row :content (filter #(not (string? %))))]
    {:href (-> href :content first :attrs :href)
     :size (-> size :content first)
     :modified (-> modified :content first)}))

(defn add-artifacts
  "given a job map, add an artifact key with all artifact urls in that job's gcs bucket"
  [job]
  (let [artifact-url (url->artifact-url (:url job))
        text (get-artifact-text! artifact-url)
        rows (artifact-text->rows text)
        artifacts (map row->artifact rows)]
    (assoc job :artifacts artifacts)))

(defn successful-jobs
  "takes a prow-deck json and gets all successful jobs, returning just the job, build, and relevant urls"
  [deck]
  (let [deck-json (json/parse-string (slurp deck) true)]
    (->> deck-json
         (filter #(= "success" (:state %)))
         (map #(select-keys % [:job :build_id :url]))
         (pmap add-artifacts))))

(files->json "./test-infra/config/jobs/" "**.yaml" "prow-jobs.json")
(files->json "./test-infra/" "**OWNERS" "owners.json")
(spit "prow-deck.json" (:body (curl/get "https://prow.k8s.io/data.js")))
(spit "job-logs.json" (json/generate-string (successful-jobs "prow-deck.json")))
