package main

import (
	"fmt"
	"math"
)

func threshold(seconds int) float64 {
	return 0.05*math.Sin(float64(seconds)/50) + 0.05
}

func main() {
	for i := 0; i < 320; i += 5 {
		fmt.Printf("%d\t%f\n", i, threshold(i))
	}
}
