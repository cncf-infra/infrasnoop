package main

import (
	"context"
	"strings"
	"fmt"
	"os"
	"sync"
	"net/http"
	// "encoding/json"
	"io"

	"github.com/jackc/pgx/v5/pgxpool"
)

var pool *pgxpool.Pool

func main() {
	var err error
	pool, err = pgxpool.New(context.Background(), os.Getenv("DATABASE_URL"))
	if err != nil {
		fmt.Fprintln(os.Stderr, "Unable to connect to database:", err)
		os.Exit(1)
	}
	defer pool.Close()
	fmt.Println("listening now")
	for {
	  listen()
	}
}

func listen() {
	conn, err := pool.Acquire(context.Background())
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error acquiring connection: ", err)
		os.Exit(1)
	}
	defer conn.Release();

	_, err = conn.Exec(context.Background(), "listen prow") // set up a postgres listen
	if err != nil {
		fmt.Fprintln(os.Stderr, "Error listening to prow channel:", err)
		os.Exit(1)
	}

	for {
		fmt.Println("hi")
		notification, err := conn.Conn().WaitForNotification(context.Background())
		if err != nil {
			fmt.Fprintln(os.Stderr, "Error waiting for notification: ", err)
		}
		fmt.Println("new notification: ", notification.Payload)
		if err = getLatestJobYamls(); err != nil {
			fmt.Fprintln(os.Stderr, "Error getting job yamls: ", err)
		}
	}
}

func getLatestJobYamls () error {
	var wg sync.WaitGroup
	conn, err := pool.Acquire(context.Background())
	defer conn.Release()
	if err != nil {
		return err
	}
	rows, err := conn.Query(context.Background(), "select job,build_id, url from prow.latest_success;")
	if err != nil {
		return err
	}
	for rows.Next() {
		var url string
		var job string
		var build_id string

		if err := rows.Scan(&job,&build_id,&url); err != nil {
			return err
		}
		go func(job string,build_id string, url string) {
			wg.Add(1)
			jobArtifactUrl := strings.Replace(url, "prow.k8s.io/view/gs/","storage.googleapis.com/",1)
			jobSpecUrl := strings.TrimRight(jobArtifactUrl,"/") + "/prowjob.json"
			resp, err := http.Get(jobSpecUrl)
			if err != nil {
				fmt.Fprintln(os.Stderr, "Error getting url: ", err)
			}
			data, err := io.ReadAll(resp.Body)
			if err != nil {
				fmt.Fprintln(os.Stderr, "Error reading body: ", err)
			}
			conn, err := pool.Acquire(context.Background())
			if err != nil {
				fmt.Fprintln(os.Stderr, "Error acquiring connection: ", err)
				os.Exit(1)
			}
			defer conn.Release();
			_, err = conn.Exec(context.Background(), "call upsertJobSpec($1,$2,$3)", job,build_id,string(data))
			if err != nil {
				fmt.Fprintln(os.Stderr, "error adding spec: ", url,err)
			}
			fmt.Println("added spec for ",job,", build", build_id)
			wg.Done()
		}(job, build_id, url)
	}
	wg.Wait()
	return nil
}
