package main

import (
	"context"
	"crypto/tls"
	"flag"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
	"os/signal"
	"time"

	"github.com/go-redis/redis/v8"
	"github.com/gorilla/websocket"
)

type event struct {
	Tag  string
	Time string
	Data data
}

type data struct {
	Time      string
	Protocol  string
	From      string
	To        string
	Message   string
	Ipv4      string
	Ipv6      string
	Mac       string
	Hostname  string
	Alias     string
	Vendor    string
	FirstSeen string `json:"first_seen"`
	LastSeen  string `json:"last_seen"`
	Meta      meta
}

type meta struct {
	values struct{}
}

var ctx = context.Background()

func main() {
	eventsAddr := flag.String("bettercapAddress", "localhost:8083", "address of the bettercap server api")
	authToken := flag.String("authToken", "", "Base64 encoded HTTP basic authorization token")
	redisAddr := flag.String("redisAddress", "localhost:6379", "Port of local redis instance")
	flag.Parse()

	interrupt := make(chan os.Signal, 1)
	signal.Notify(interrupt, os.Interrupt)

	if *eventsAddr == "" || *authToken == "" || *redisAddr == "" {
		flag.PrintDefaults()
		os.Exit(1)
	}

	u := url.URL{Scheme: "wss", Host: *eventsAddr, Path: "/api/events"}
	log.Printf("(bettercap) connecting to %s", u.String())

	// Disable SSL verification
	websocket.DefaultDialer.TLSClientConfig = &tls.Config{InsecureSkipVerify: true}

	// Connect to socket
	c, response, err := websocket.DefaultDialer.Dial(u.String(), http.Header{"Authorization": {fmt.Sprintf("Basic %s", *authToken)}})
	if err != nil {
		log.Fatal("received error: ", err, response.StatusCode)
	} else {
		log.Printf("connection established to event stream")
	}
	defer c.Close()

	// Connect to Redis
	log.Printf("(redis) connecting to %s", *redisAddr)
	rdb := redis.NewClient(&redis.Options{
		Addr:        *redisAddr,
		DialTimeout: 1 * time.Second,
	})

	err = rdb.Info(ctx, "clients").Err()
	if err != nil {
		panic(err)
	}
	log.Printf("connection established to redis")

	done := make(chan bool)

	go func() {
		e := event{}

		for {
			select {

			case <-done:
				log.Println("closing listener...")
				return

			default:
				err := c.ReadJSON(&e)
				if err != nil {
					log.Println("error unmarshaling event:", err)
				}

				if e.Tag == "net.sniff.http" || e.Tag == "net.sniff.https" {
					err = rdb.HIncrBy(ctx, e.Data.From, e.Data.To, 1).Err()
					if err != nil {
						log.Printf("error caching data for %s -> %s\n%s\n", e.Data.From, e.Data.To, err)
					}
				} else if e.Tag == "endpoint.new" || e.Tag == "endpoint.lost" {
					eventStr := generateEventStr(e)
					err = rdb.RPush(ctx, "endpoints", eventStr).Err()
					if err != nil {
						log.Println("error caching endpoint change: ", err, eventStr)
					}
				}
			}
		}
	}()

	for {
		select {

		case <-interrupt:
			log.Println("interrupted, exiting...")

			err = rdb.Close()
			if err != nil {
				log.Println("error closing redis connection: ", err)
			}

			done <- true
			return
		}
	}
}

func generateEventStr(e event) string {
	hostname := getOrDefault(e.Data.Hostname, "[no hostname]")
	alias := getOrDefault(e.Data.Alias, "[no alias]")
	vendor := getOrDefault(e.Data.Vendor, "[no vendor]")

	return fmt.Sprintf("%s, %s, %s, %s, %s, %s, %s, %s, %s",
		e.Time, e.Tag, e.Data.Ipv4, e.Data.Mac, hostname, alias, vendor,
		e.Data.FirstSeen, e.Data.LastSeen)
}

func getOrDefault(val, def string) string {
	if val == "" {
		return def
	}
	return val
}
