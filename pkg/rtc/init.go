package rtc

import (
	"errors"
	"sync"
	"time"

	"github.com/pion/ion/pkg/rtc/udp"
	"github.com/pion/webrtc/v2"
)

const (
	maxPipelineSize = 1024

	pktSize = 100

	jitterBuffer = "JB"

	//for remb
	rembDuration = 3 * time.Second
	rembLowBW    = 30 * 1000
	rembHighBW   = 100 * 1000

	receiveMTU  = 8192
	extSentInit = 30

	//for pli
	pliDuration = 1 * time.Second

	statDuration = 3 * time.Second
)

var (
	cfg webrtc.Configuration

	errInvalidParam  = errors.New("invalid param")
	errChanClosed    = errors.New("channel closed")
	errInvalidTrack  = errors.New("track not found")
	errInvalidPacket = errors.New("packet is nil")

	listener *udp.Listener
	pipes    = make(map[string]*pipeline)
	pipeLock sync.RWMutex
)

func Init(port int, ices []string) {
	serve(port)
	initICE(ices)
	go func() {
		t := time.NewTicker(statDuration)
		for {
			select {
			case <-t.C:
				Stat()
			}
		}
	}()
}
