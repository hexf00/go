package main

/*
#include <stdlib.h>
*/
import "C"
import (
	"os"
	"runtime"
	"sync"
)

//export GoProbe
func GoProbe() C.int {
	// Exercise Go -> C -> Go, including _cgo_topofstack. With frame
	// pointers enabled this detects TLS resolver stack corruption.
	p := C.calloc(1, 32)
	if p == nil {
		return -2
	}
	C.free(p)
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
