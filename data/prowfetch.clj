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
(pods/load-pod 'org.babashka/postgresql "0.1.0")
(require '[pod.babashka.postgresql :as pg])
(require '[pod.babashka.postgresql.sql :as sql])

(defn distinct-by
  "Returns a stateful transducer that removes elements by calling f on each step as a uniqueness key.
   Returns a lazy sequence when provided with a collection."
  ([f]
   (fn [rf]
     (let [seen (volatile! #{})]
       (fn
         ([] (rf))
         ([result] (rf result))
         ([result input]
          (let [v (f input)]
            (if (contains? @seen v)
              result
              (do (vswap! seen conj v)
                  (rf result input)))))))))
  ([f xs]
   (sequence (distinct-by f) xs)))


(def ztest [{:name "z" :time 3} {:name "z" :time 1} {:name "h" :time 1} {:name "z" :time 2} {:name "h" :time 0}])

(distinct-by :name ztest)


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
  (let [url-root "https://gcsweb.k8s.io"
        replace-prow (fn [url] (str/replace url #"^https://prow.k8s.io/view/gs" (str url-root "/gcs")))
        absolute-url (fn [url] (if (not (str/starts-with? url url-root))
                                 (str url-root url) url))
        trailing-slash (fn [url] (if (not (str/ends-with? url "/"))
                                   (str url "/") url))]
    (-> url
        replace-prow
        absolute-url
        trailing-slash
        )))

(defn get-artifact-text! [url]
  (try
    (:body (curl/get url))
    (catch Exception e
      (println "error getting artifact text for "url ": " (ex-message e))
      "")))

(defn artifact-text->rows
  [text]
  (let [artifact-soup (-> text
                          (str/replace #"(\n|\t|<!doctype html>)" "")
                          str/trim
                          (convert-to :hickory))]
    (->> artifact-soup
         (s/select (s/descendant (s/class "grid-row")))
         (drop 1))))

(defn row->artifact
  [row]
  (let [[hrefhick sizehick modhick] (->> row :content (filter #(not (string? %))))
        url (-> hrefhick :content first :attrs :href)
        size (-> sizehick :content first)
        modified (-> modhick :content first)]
    {:url url
     :size size
     :modified modified}))

(defn get-all-artifacts
  [url]
  (let [artifact-url (url->artifact-url url)
        text (get-artifact-text! artifact-url)
        rows (artifact-text->rows text)
        artifacts-at-level (map row->artifact rows)]
    (pmap #(if (str/ends-with? (:url %) "/")
            (get-all-artifacts (:url %))
            %) artifacts-at-level)))

(defn add-artifacts
  "given a job map, add an artifact key with all artifact urls in that job's gcs bucket"
  [job]
  (let [artifacts (flatten (get-all-artifacts (:url job)))]
    (assoc job :artifacts artifacts)))

(defn successful-jobs
  "takes a prow-deck json and gets all successful jobs, returning just the job, build, and relevant urls"
  []
  (let [deck-json (json/parse-string (:body (curl/get "prow.k8s.io/data.js")) true)]
    (->> deck-json
         (filter #(= "success" (:state %)))
         (sort-by :started)
         (distinct-by :job)
         (map #(select-keys % [:job :build_id :url]))
         (pmap add-artifacts))))


(files->json "./test-infra/config/jobs/" "**.yaml" "prow-jobs.json")
(files->json "./test-infra/" "**OWNERS" "owners.json")


(def db {:dbtype "postgresql"
         :host "localhost"
         :dbname "postgres"
         :user "postgres"
         :password "infra"
         :port 5432})

(pg/execute! db ["insert into "])

(sql/insert-multi! db :prow.artifact
                  [:job :build_id]
                  [["zach is cool" "good"]])


(def jobs (successful-jobs))



                 (json/parse-string (:body (curl/get (:url (nth (:artifacts (first jobs)) 4)))))

(pg/execute! db ["insert into prow.artifact(job,build_id,data,filetype)
values('testing','1234',?,'json');"
                 (pg/write-jsonb (json/parse-string (:body (curl/get (:url (nth (:artifacts (first jobs)) 4))))))])


(sql/insert-multi! db :prow.artifact
                   [:job :build_id :data :filetype]
                   [["testing"
                     "123"
                     (json/parse-string (:body (curl/get (:url (nth (:artifacts (first jobs)) 3)))))
                     "json"]])

(defn parse-filetype
  [url]
  (let [ext? (fn [ext] (str/ends-with? (str/lower-case url) ext))]
    (cond
      (ext? "json") "json"
      (or (ext? "yaml") (ext? "yml")) "yaml"
      (ext? "log") "log"
      :else "text")))

(defn parse-content
  [ext content]
  (if (:prowfetch_error content)
    content
    (cond
      (= ext "json") (json/parse-string content)
      (= ext "yaml") (yaml/parse-string content)
      :else (assoc {} :content content))))

(defn get-content!
  [url]
  (try
    (:body (curl/get url))
    (catch Exception e
      (println e)
      {:prowfetch_error e})))


(defn insert-artifact!
  [job build_id {:keys [url size modified]}]
  (let [filetype (parse-filetype url)
        raw-content (get-content! url)
        data (pg/write-jsonb (parse-content filetype raw-content))]
    (try
      (pg/execute! db
                   ["insert into prow.artifact(job,build_id,url,size,modified,data,filetype) values(?,?,?,?,?,?,?);"
                    job build_id url size modified data filetype])
      (println "ARTIFACT ADDED for " job " "build_id " "url)
      (catch Exception e
        (println e)))))

(defn insert-artifacts!
  [{:keys [job build_id] :as dajob} ]
  (pmap #(insert-artifact! job build_id %) (:artifacts dajob)))

(pmap insert-artifacts! (successful-jobs))
