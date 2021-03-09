package main

import (
  "net"
  "time"
  "sync/atomic"

  "github.com/bettercap/bettercap/log"
  "github.com/chifflier/nfqueue-go/nfqueue"
  "github.com/google/gopacket"
  "github.com/google/gopacket/layers"
  "github.com/evilsocket/islazy/tui"
)

var raspberryPiIP net.IP = net.ParseIP("192.168.0.17")
var label = tui.Wrap(tui.BACKRED, tui.Wrap(tui.FOREBLACK, "needler"))

var quit chan bool

var dropped uint64
var passed uint64

func init() {
  // Use buffered channel so that the sleeping heartbeat goroutine
  // doesn't block the main thread.
  quit = make(chan bool, 2)
}

func heartbeat() {
  for {
    select {
      case <- quit:
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
        time.Sleep(60 * time.Second)
    }
  }
}

func OnStart() int {
  atomic.StoreUint64(&dropped, 0)
  atomic.StoreUint64(&passed, 0)

  go heartbeat()

  return 0
}

func OnStop() {
  atomic.StoreUint64(&dropped, 0)
  atomic.StoreUint64(&passed, 0)

  // Signal the heartbeat goroutine to exit.
  quit <- true
}

// OnPacket callback from packet proxy.
func OnPacket(payload *nfqueue.Payload) int {
  packet := gopacket.NewPacket(payload.Data, layers.LayerTypeIPv4, gopacket.NoCopy)

  var srcIP net.IP
  if ipv4Layer := packet.Layer(layers.LayerTypeIPv4); ipv4Layer != nil {
    ipv4, _ := ipv4Layer.(*layers.IPv4)
    srcIP = ipv4.SrcIP
  }

  /*
   * Originally I was setting the verdict here to accept, and then setting it again
   * to drop in the branch. That didn't work though - it seems like whatever you set
   * first as the verdict sticks?
   */
  if !raspberryPiIP.Equal(srcIP) {
    atomic.AddUint64(&dropped, 1)
    payload.SetVerdict(nfqueue.NF_DROP)
  } else {
    atomic.AddUint64(&passed, 1)
    payload.SetVerdict(nfqueue.NF_ACCEPT)
  }

  return 0
}

