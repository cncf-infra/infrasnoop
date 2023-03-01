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
  [deck]
  (let [deck-json (json/parse-string (slurp deck) true)]
    (->> deck-json
         (filter #(= "success" (:state %)))
         (sort-by :started)
         (distinct-by :job)
         (map #(select-keys % [:job :build_id :url]))
         (pmap add-artifacts))))


(files->json "./test-infra/config/jobs/" "**.yaml" "prow-jobs.json")
(files->json "./test-infra/" "**OWNERS" "owners.json")
(spit "prow-deck.json" (:body (curl/get "https://prow.k8s.io/data.js")))
;; (spit "job-artifacts.json" (json/generate-string (successful-jobs "prow-deck.json")))


;; (spit "job-artifacts-test.json"
;;       (json/generate-string
;;        (flatten
;;         (get-all-artifacts "https://gcsweb.k8s.io/gcs/kubernetes-jenkins/logs/test-infra-cfl-coverage-report/1630446352808808448/"))))

(spit "job-artifacts-test.json"
      (json/generate-string
       (successful-jobs "prow-deck.json")))
