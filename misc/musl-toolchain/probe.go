package main

import "C"
import (
	"os"
	"runtime"
	"sync"
)

//export GoProbe
func GoProbe() C.int {
	if os.Getenv("MUSL_PROBE") != "expected" {
		return -1
	}
	var wg sync.WaitGroup
	for i := 0; i < 32; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			b := make([]byte, 256*1024)
			for j := range b {
				b[j] = byte(j)
			}
			runtime.KeepAlive(b)
		}()
	}
	wg.Wait()
	runtime.GC()
	return 42
}
func main() {}
