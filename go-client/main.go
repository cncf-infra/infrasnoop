package main

import (
	"context"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"sync"

	"github.com/PuerkitoBio/goquery"
	"github.com/jackc/pgx/v5/pgxpool"
	"sigs.k8s.io/yaml"
)

var pool *pgxpool.Pool

func main() {
	var err error
	pool, err = pgxpool.New(context.Background(), os.Getenv("DATABASE_URL"))
	if err != nil {
		log.Fatal("Unable to connect to database: ", err)
	}
	defer pool.Close()
	listen()
}

func listen() {
	conn, err := pool.Acquire(context.Background())
	if err != nil {
		log.Fatal("Error acquiring connection: ", err)
	}
	defer conn.Release()

	_, err = conn.Exec(context.Background(), "listen prow") // set up a postgres listen
	if err != nil {
		log.Fatal("Error listening to prow channel: ", err)
	}
	fmt.Println("listening now")

	for {
		notification, err := conn.Conn().WaitForNotification(context.Background())
		if err != nil {
			log.Println("Error wiating for notification: ", err)
		}
		log.Println("New notification", notification.Payload)
		log.Println("Fetching prow job specs")
		if err = getLatestJobYamls(); err != nil {
			log.Println("Error getting job yamls: ", err)
		}
		log.Println("Job specs gathered. Listening...")
	}
}

func getLatestJobYamls() error {
	var wg sync.WaitGroup
	conn, err := pool.Acquire(context.Background())
	defer conn.Release()
	if err != nil {
		return err
	}
	latestSuccessQuery := "select job, build_id, url from prow.latest_success"

	rows, err := conn.Query(context.Background(), latestSuccessQuery)
	if err != nil {
		return err
	}
	for rows.Next() {
		var url string
		var job string
		var build_id string

		if err := rows.Scan(&job, &build_id, &url); err != nil {
			return err
		}
		wg.Add(1)
		go func(job string, build_id string, url string) {
			prowspec, err := getProwSpec(url)
			if err != nil {
				log.Println("Error getting prowspec: ", err)
			}
			conn, err := pool.Acquire(context.Background())
			if err != nil {
				log.Fatal("Error acquiring connection: ", err)
			}
			defer conn.Release()

			upsertCall := "call upsertJobSpec($1,$2,$3)" //job,build_id,prowspec
			_, err = conn.Exec(context.Background(), upsertCall, job, build_id, prowspec)
			if err != nil {
				log.Println("error adding spec: ", url, err)
			}
			log.Println("added spec for ", job, ", build", build_id)
			wg.Done()
		}(job, build_id, url)
	}
	wg.Wait()
	return err
}

func getProwSpec(url string) (spec string, err error) {
	res, err := http.Get(url)
	if err != nil {
		return "", err
	}
	defer res.Body.Close()
	if res.StatusCode != 200 {
		err = fmt.Errorf("Did not get 200 status code: %v", err)
		return "", err
	}
	doc, err := goquery.NewDocumentFromReader(res.Body)
	if err != nil {
		err = fmt.Errorf("goquery could not parse url body(%v):%v", url, err)
		return "", err
	}

	var prowYamlLink string
	doc.Find("#links-card a").Each(func(i int, s *goquery.Selection) {
		content := s.Text()
		if content == "Prow Job YAML" {
			path, ok := s.Attr("href")
			if !ok {
				fmt.Fprintln(os.Stderr, "Found prow job link, but it has no href? ", url)
			}
			prowYamlLink = "https://prow.k8s.io" + path
		}
	})
	if prowYamlLink == "" {
		err := fmt.Errorf("Could not find a link to yaml for %v", url)
		return "", err
	}

	jsonString, err := prowAsJson(prowYamlLink)
	if err != nil {
		err = fmt.Errorf("Could not get prow spec as json string(%v): %v", url, err)
		return "", err
	}
	return jsonString, nil
}

func prowAsJson(url string) (jsonString string, err error) {
	res, err := http.Get(url)
	if err != nil {
		err := fmt.Errorf("Error getting link from given url %v: %v", url, err)
		return "", err
	}
	yamldata, err := io.ReadAll(res.Body)
	if err != nil {
		err = fmt.Errorf("Error reading body of yaml: ", err)
		return "", err
	}
	jsonData, err := yaml.YAMLToJSON(yamldata)
	if err != nil {
		err = fmt.Errorf("Could not parse yaml to json for %v: %v", url, err)
		return "", err
	}
	return string(jsonData), err
}
