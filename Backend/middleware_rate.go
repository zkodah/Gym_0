package main

import (
	"net"
	"net/http"
	"sync"
	"time"
)

type bucket struct {
	mu       sync.Mutex
	count    int
	windowAt time.Time
}

var (
	buckets   sync.Map
	windowDur = time.Minute
)

func getRateBucket(ip string) *bucket {
	v, _ := buckets.LoadOrStore(ip, &bucket{windowAt: time.Now()})
	return v.(*bucket)
}

func limitarPorIP(limit int, next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		ip, _, err := net.SplitHostPort(r.RemoteAddr)
		if err != nil {
			ip = r.RemoteAddr
		}

		b := getRateBucket(ip)
		b.mu.Lock()
		if time.Since(b.windowAt) >= windowDur {
			b.count = 0
			b.windowAt = time.Now()
		}
		b.count++
		over := b.count > limit
		b.mu.Unlock()

		if over {
			http.Error(w, "Demasiadas peticiones. Intenta de nuevo en un minuto.", http.StatusTooManyRequests)
			return
		}
		next(w, r)
	}
}
