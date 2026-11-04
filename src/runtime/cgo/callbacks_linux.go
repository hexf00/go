// Copyright 2026 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package cgo

import _ "unsafe"

// x_cgo_isglibc is set during x_cgo_init before runtime.sysargs.
// A separate Linux file keeps this Linux-only C symbol off other targets.

//go:cgo_import_static x_cgo_isglibc
//go:linkname x_cgo_isglibc x_cgo_isglibc
//go:linkname _cgo_isglibc _cgo_isglibc
var x_cgo_isglibc byte
var _cgo_isglibc = &x_cgo_isglibc
