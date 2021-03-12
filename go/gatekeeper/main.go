package main

import (
	"io/ioutil"
	"math"
	"math/rand"
	"net"
	"strconv"
	"sync/atomic"
	"time"
	"unsafe"

	"github.com/bettercap/bettercap/log"
	"github.com/chifflier/nfqueue-go/nfqueue"
	"github.com/evilsocket/islazy/tui"
	"github.com/google/gopacket"
	"github.com/google/gopacket/layers"
)

var raspberryPiIP net.IP = net.ParseIP("192.168.0.17")
var label = tui.Wrap(tui.BACKRED, tui.Wrap(tui.FOREBLACK, "gatekeeper"))

var quit chan bool

var dropped uint64
var passed uint64
var threshold float64

func init() {
	// Use buffered channel so that the sleeping heartbeat goroutine
	// doesn't block the main thread.
	quit = make(chan bool, 2)
}

func updateThreshold(useFile bool) {
	for {
		select {
		case <-quit:
			log.Info("%s Threshold update shutting down...", label)
			return
		default:
			if useFile {
				oldThreshold := atomicLoadFloat64(&threshold)
				dat, err := ioutil.ReadFile("/home/pi/threshold")
				if err != nil {
					log.Error("%s Failed to load threshold file: ", label, err)
				}
				newThreshold, err := strconv.ParseFloat(string(dat), 64)
				if err != nil {
					log.Error("%s Failed to parse threshold: ", label, err)
				}

				if newThreshold != oldThreshold {
					log.Info("%s Threshold Changed from %f to %f", label, oldThreshold, newThreshold)
				}
				atomicStoreFloat64(&threshold, newThreshold)
			} else {
				seconds := time.Now().Unix() % 300                          // 5 minute cycle
				newThreshold := 0.15*math.Sin(float64(seconds)/47.8) + 0.35 // Oscillate between 20% and 50% packet loss.
				atomicStoreFloat64(&threshold, newThreshold)
			}
			time.Sleep(5)
		}
	}
}

func heartbeat() {
	for {
		select {
		case <-quit:
			log.Info("%s Heartbeat shutting down...", label)
			return
		default:
			d := atomic.LoadUint64(&dropped)
			p := atomic.LoadUint64(&passed)
			total := p + d
			pctDropped := 0.0
			if total > 0 {
				pctDropped = float64(dropped) / float64(total) * 100.0
			}
			log.Info("%s Passed: %d - Dropped: %d (%.2f%%) - Total: %d", label, p, d, pctDropped, total)
			log.Info("%s Current Threshold: %f", label, atomicLoadFloat64(&threshold))
			time.Sleep(30 * time.Second)
		}
	}
}

// OnStart callback from packet proxy
func OnStart() int {
	atomic.StoreUint64(&dropped, 0)
	atomic.StoreUint64(&passed, 0)
	atomicStoreFloat64(&threshold, 0.0)

	go heartbeat()
	go updateThreshold(false)

	return 0
}

// OnStop callback from packet proxy
func OnStop() {
	atomic.StoreUint64(&dropped, 0)
	atomic.StoreUint64(&passed, 0)
	atomicStoreFloat64(&threshold, 0.0)

	// Signal background goroutines to exit.
	close(quit)
}

// OnPacket callback from packet proxy.
func OnPacket(payload *nfqueue.Payload) int {
	packet := gopacket.NewPacket(payload.Data, layers.LayerTypeIPv4, gopacket.NoCopy)

	var srcIP net.IP
	var dstIP net.IP
	if ipv4Layer := packet.Layer(layers.LayerTypeIPv4); ipv4Layer != nil {
		ipv4, _ := ipv4Layer.(*layers.IPv4)
		srcIP = ipv4.SrcIP
		dstIP = ipv4.DstIP
	}

	/*
	 * Originally I was setting the verdict here to accept, and then setting it again
	 * to drop in the branch. That didn't work though - it seems like whatever you set
	 * first as the verdict sticks?
	 */
	if !raspberryPiIP.Equal(srcIP) && !raspberryPiIP.Equal(dstIP) &&
		rand.Float64() < atomicLoadFloat64(&threshold) {
		atomic.AddUint64(&dropped, 1)
		payload.SetVerdict(nfqueue.NF_DROP)
	} else {
		atomic.AddUint64(&passed, 1)
		payload.SetVerdict(nfqueue.NF_ACCEPT)
	}

	return 0
}

func atomicStoreFloat64(x *float64, newValue float64) {
	atomic.StoreUint64((*uint64)(unsafe.Pointer(x)), math.Float64bits(newValue))
}

func atomicLoadFloat64(x *float64) float64 {
	return math.Float64frombits(atomic.LoadUint64((*uint64)(unsafe.Pointer(x))))
}
