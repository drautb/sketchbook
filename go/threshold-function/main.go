package main

import (
	"fmt"
	"math"
	"time"
)

func threshold() float64 {
	seconds := time.Now().Unix() % 315
	return math.Max(0.7, 0.25*math.Sin(float64(seconds)/50)+0.75)
}

func main() {
	for i := 0; i < 70; i++ {
		fmt.Printf("%d\t%f\n", i, threshold())
		time.Sleep(5 * time.Second)
	}
}
