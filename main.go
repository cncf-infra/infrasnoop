package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"

	"k8s.io/test-infra/prow/config"
)

type ProwJob struct {
	Name string
	Type string
	Data []byte
}

type JobResultCache struct {
	BuildNumber string `json:"buildnumber"`
	JobVersion  string `json:"job-version"`
	Version     string `json:"version"`
	Result      string `json:"result"`
	Passed      string `json:"passed"`
}

func WriteJobAsJSONFile(j interface{}) error {
	data, err := json.Marshal(j)
	if err != nil {
		return fmt.Errorf("Error marshalling json data, %v", err)
	}
	fileToWrite := runtimeConfig.Output
	f, err := os.OpenFile(fileToWrite, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0777)
	if err != nil {
		return fmt.Errorf("Error open new json data (%v), %v", fileToWrite, err)
	}
	defer f.Close()
	if _, err := f.WriteString(string(data) + "\n"); err != nil {
		return fmt.Errorf("Error write string to json data (%v), %v", fileToWrite, err)
	}
	return nil
}

var (
	runtimeConfig = &Config{}
)

func (c *Config) LoadJobs() error {
	jobConfig, err := config.ReadJobConfig(runtimeConfig.Path)
	if err != nil {
		return fmt.Errorf("Error reading job config, %v", err)
	}
	periodics := jobConfig.AllPeriodics()
	preSubmits := jobConfig.AllStaticPresubmits(jobConfig.AllRepos.List())
	postSubmits := jobConfig.AllStaticPostsubmits(jobConfig.AllRepos.List())

	log.Printf("Periodics (%v)\n", len(periodics))
	for _, j := range periodics {
		err = WriteJobAsJSONFile(j)
		if err != nil {
			return fmt.Errorf("Error loading job data, %v", err)
		}
	}
	log.Printf("PreSubmits (%v)\n", len(preSubmits))
	for _, j := range preSubmits {
		err = WriteJobAsJSONFile(j)
		if err != nil {
			return fmt.Errorf("Error loading job data, %v", err)
		}
	}
	log.Printf("PostSubmits (%v)\n", len(postSubmits))
	for _, j := range postSubmits {
		err = WriteJobAsJSONFile(j)
		if err != nil {
			return fmt.Errorf("Error loading job data, %v", err)
		}
	}
	return nil
}

type JobInfo struct {
	LatestBuild  string
	ResultsCache []byte
}

func GetAFile(url string) (body string, err error) {
	resp, err := http.Get(url)
	if err != nil {
		return "", fmt.Errorf("Error fetching %v, %v\n", url, err)
	}
	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("Bad status code (%v) for '%v'\n", resp.StatusCode, url)
	}
	defer resp.Body.Close()
	bodyBytes, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Fatalf("Error reading body from url %v, %v\n", url, err)
	}
	return string(bodyBytes), nil
}

type Config struct {
	Reset  bool
	Path   string
	Output string
}

func init() {
	flag.BoolVar(&runtimeConfig.Reset, "reset", false, "resets the database")
	flag.StringVar(&runtimeConfig.Path, "path", "/tmp/src-test-infra/config/jobs", "the path to the ProwJobs")
	flag.StringVar(&runtimeConfig.Output, "output", "/tmp/infrasnoop-jobs.json", "the path of where to write the infrasnoop-jobs.json file")
	flag.Parse()
}

func main() {
	err := runtimeConfig.LoadJobs()
	if err != nil {
		log.Printf("Error loading jobs, %v", err)
		return
	}
	log.Println("Complete.")
}
