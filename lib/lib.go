package lib

/*
#cgo !windows LDFLAGS: -lcrypto -ldl -lpthread
#cgo windows LDFLAGS: -L/opt/mingw64/lib -lcrypto
#cgo windows CFLAGS: -I/opt/mingw64/include
#include <openssl/rsa.h>
*/
import "C"

func Test() {
	C.RSA_new()
}
