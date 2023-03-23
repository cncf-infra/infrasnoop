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

(defn url->gcs-url
  "replace prow link to the gcs artifact dir link"
  [url]
  (let [url-root "https://gcsweb.k8s.io"
        replace-prow (fn [url] (str/replace url #"^https://prow.k8s.io/view/gs" (str url-root "/gcs")))
        absolute-url (fn [url] (if (not (str/starts-with? url url-root))
                                 (str url-root url) url))
        add-trailing-slash (fn [url] (if (not (str/ends-with? url "/"))
                                   (str url "/") url))]
    (-> url
        replace-prow
        absolute-url
        add-trailing-slash)))

(defn get-gcs-text!
  [<job]
  (let [job> (chan)]
    (go-loop []
      (when-some [job (<! <job)]
        (let [url (url->gcs-url (:url job))]
          (try
            (let [text (:body (client/get url))]
              (>! job> (assoc job :gcs-text text)))
            (catch Exception e
              (do (println "Error fetching "url ": " (ex-message e))
                  (>! job> (assoc job :gcs-text "")))))))
      (recur))
    job>))

(defn select-rows
  [job]
  (let [soup (-> (:gcs-text job)
                 (str/replace #"(\n|\t|<!doctype html>)" "")
                 str/trim
                 hick/parse
                 hick/as-hickory)
        rows (->> soup
                  (s/select
                   (s/descendant
                    (s/class "grid-row")))
                  (drop 1))]
    (-> job
        (assoc :rows rows :gcs-text ""))))


(defn gcs-text->rows
  [<job]
  (let [rows> (chan)]
    (go-loop [] (when-some [job (<! <job)]
                  (>! rows> (select-rows job)))
             (recur))
    rows>))

(defn row->artifact-metadata
  [row]
  (let [[hrefhick sizehick modhick] (->> row :content (filter #(not (string? %))))
        url (-> hrefhick :content first :attrs :href)
        size (-> sizehick :content first)
        modified (-> modhick :content first)]
    {:url url
     :size size
     :modified modified}))

(defn get-job-artifacts
  [{:keys [rows job build_id]}]
  (
   let [artifacts (map row->artifact-metadata rows)]
   (map #(assoc % :job job :build_id build_id) artifacts)))

(defn allowed-url?
  [{:keys [url]}]
  (or (not (str/ends-with? url "bin/"))
      (not (str/ends-with? url "pkg/"))))

(defn rows->artifact-links
  [<job]
  (let [links> (chan)]
    (go-loop []
        (when-some [job (<! <job)]
          (->> job
               get-job-artifacts
               (filter allowed-url?)
               (>! links>)))
      (recur))
    links>))

(defn dispatch-links
  [<links job>]
  (let [artifact-link> (chan)
        dir-link? (fn [l] (str/ends-with? l "/"))]
    (go (while true
          (let [links (<! <links)]
            (doseq [link links]
              (if (dir-link? (:url link))
                (>! job> link)
                (>! artifact-link> link))))))
    artifact-link>))

(defn printer
  [in]
  (go-loop []
    (when-some [success (<! in)]
      (println success))
    (recur)))

(defn get-blob
  [<artifact]
  (let [artifact> (chan)]
    (go-loop []
      (when-some [artifact (<! <artifact)]
        (try
          (let [data (:body (client/get (:url artifact)))]
            (>! artifact> (assoc artifact :data data)))
          (catch Exception e
            (>! artifact> (assoc artifact :data (str "SIDELOADER ERROR: " (ex-message e)))))))
      (recur))
    artifact>))

(defn insert-artifact!
  [<artifact]
  (let [db> (chan)]
    (go-loop []
      (when-some [artifact (<! <artifact)]
        (try (db/insert-artifact db/conn artifact)
             (>! db> (str "ARTIFACT ADDED: " (:url artifact)))
             (catch Exception e
               (>! db> (str "COULD NOT INSERT ARTIFACT(: " (:url artifact) (ex-message e))))))
      (recur))
    db>))

(defn -main []
  (println "starting it up!")
  (println (:add_prow_deck_jobs (db/add-prow-deck-jobs db/conn)))
(let [jobs-without-artifacts (db/success-without-artifacts db/conn)
      in-chan (chan)
      text-out (get-gcs-text! in-chan)
      rows-out (gcs-text->rows text-out)
      links-out (rows->artifact-links rows-out)
      artifact-out (dispatch-links links-out in-chan)
      artifact-blob-out (get-blob artifact-out)
      db-out (insert-artifact! artifact-blob-out)]
  (doseq [job jobs-without-artifacts]
    (>!! in-chan job))
  (<!! (printer db-out))))
