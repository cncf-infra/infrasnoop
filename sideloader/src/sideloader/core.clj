(ns sideloader.core
  (:require [clojure.core.async
             :as a
             :refer [>! <! >!! <!! go chan buffer close! thread
                     alts! alts!! timeout go-loop]]
            [sideloader.db.core :as db]
            [clojure.string :as str]
            [clj-http.client :as client]
            [clojure.data]
            [hickory.core :as hick]
            [clj-yaml.core :as yaml]
            [clojure.data.json :as json]
            [hickory.select :as s]))

(defn parse-filetype
  [url]
  (let [ext? (fn [ext] (str/ends-with? (str/lower-case url) ext))]
    (cond
      (ext? "json") "json"
      (or (ext? "yaml") (ext? "yml")) "yaml"
      (ext? "log") "log"
      (or (ext? "txt") (ext? "text")) "text"
      :else "other")))

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
        trailing-slash)))

(defn get-artifact-text! [url]
  (try
    (:body (client/get url))
    (catch Exception e
      (println "error getting artifact text for "url ": " (ex-message e))
      "")))

(defn artifact-text->rows
  [text]
  (let [artifact-soup (-> text
                          (str/replace #"(\n|\t|<!doctype html>)" "")
                          str/trim
                          hick/parse hick/as-hickory)]
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
        artifacts-at-level (map row->artifact rows)
        artifacts-sans-pkgs (filter #(or (not (str/ends-with? (:url %) "bin/"))
                                         (not (str/ends-with? (:url %) "pkg/"))
                                      ) artifacts-at-level)]
    (pmap #(if (str/ends-with? (:url %) "/")
            (get-all-artifacts (:url %))
            %) artifacts-sans-pkgs)))

(defn add-artifacts
  "given a job map, add an artifact key with all artifact urls in that job's gcs bucket"
  [job]
  (let [artifacts (flatten (get-all-artifacts (:url job)))]
    (map #(assoc %
                 :job (:job job)
                 :build_id (:build_id job)
                 :filetype (parse-filetype (:url %)))
         artifacts)))

(defn get-blob!
  [url]
  (try
    (let [blob (:body (client/get url))]
      blob)
    (catch Exception e
      {:sideloader_error (ex-message e)})))

(defn artifact+blob
  [artifact]
  (let [blob (if (= "other" (:filetype artifact))
               {:sideloader_error "unknown filetype, skipping for now"}
               (get-blob! (:url artifact)))]
    (assoc artifact :raw_data blob)))


(defn parse-raw-data
  [{:keys [filetype raw_data] :as artifact}]
  (cond
    (:sideloader_error raw_data) raw_data
    (= "json" filetype) (json/read-str raw_data)
    (= "yaml" filetype) (yaml/parse-string raw_data)
    (or (= "log" filetype) (= "text" filetype)) {:content raw_data}
    :else {:sideloader_error "issue parsing raw data "}))

(defn artifact+parsed-raw
  [artifact]
  (let [data (parse-raw-data (:raw_data artifact))]
    (assoc artifact :data data)))

(defn insert-artifact!
  [artifact]
  (let [readied-artifact (assoc artifact
                                :data (json/write-str (:data artifact))
                                :raw_data (json/write-str (:raw_data artifact)))]
    (try
      (db/add-prow-artifact db/conn readied-artifact)
      (catch Exception e
        (ex-message e)))))

(defn artifacts-pipeline
  [artifacts]
  (let [c1 (chan)
        c2 (chan)
        c3 (chan)
        c4 (chan)]
    (go-loop []
      (when-some [a (<! c1)]
        (>! c2 (artifact+blob a))
        (recur)))
    (go-loop []
      (when-some [a (<! c2)]
        (>! c3 (artifact+parsed-raw a)))
      (recur))
    (go-loop []
      (when-some [a (<! c3)]
          (>! c4 (insert-artifact! a)))
      (recur ))
    (go-loop [count 1]
      (when-some [a (<! c4)]
        (println count ": "a))
      (recur (inc count)))
    (doseq [artifact artifacts]
      (>!! c1 artifact))
    (close! c1)))

(defn -main
  []
  (println "starting it up!")
  (println (:add_prow_deck_jobs (db/add-prow-deck-jobs db/conn)))
  (let [jobs-without-artifacts (db/success-without-artifacts db/conn)
        artifacts (apply concat (pmap add-artifacts jobs-without-artifacts))]
    (println "loading " (count artifacts) " artifacts")
    )) ;; (<!! (go (artifacts-pipeline artifacts)))
