package main

import (
	"fmt"
	"math/rand"
	"net/http"
	"time"
)

func main() {
	http.HandleFunc("/hello", hellohandler)
	http.HandleFunc("/now", nowhandler)
	http.HandleFunc("/dice", dicehandler)
	http.HandleFunc("/headers", headers)
	http.HandleFunc("/headera", headera) //追加

	http.ListenAndServe(":8980", nil)
}
func hellohandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "こんにちは from Cocespace !")
}
func nowhandler(w http.ResponseWriter, r *http.Request) {
	jst, _ := time.LoadLocation("Asia/Tokyo")
	fmt.Fprintln(w, (time.Now().In(jst)).Format("2006年01月02日 15:04:05"))
}
func dicehandler(w http.ResponseWriter, r *http.Request) {
	seed := time.Now().UnixNano()
	d := rand.New(rand.NewSource(seed))
	fmt.Fprintln(w, d.Int31n(5)+1)
}
func headers(w http.ResponseWriter, r *http.Request) {
	h := r.Header
	fmt.Fprintln(w, h)
}
// 一部ヘッダを取得する例．追加
func headera(w http.ResponseWriter, r *http.Request) {
	var h map[string][]string
	h = r.Header
	fmt.Fprintln(w, h["Accept-Encoding"][0])
}
