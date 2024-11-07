---
tags:
  - linux
  - lolgolf

---

Challenge:
  * serve the output of a linux command with an http server

with nc
```
while true; do { echo -ne "HTTP/1.0 200 OK\r\n\r\n"; cat hello.txt; } | nc -q1 -l -p 8080; done
```

cheating by installing socat but the cleanest option sofar

```bash
socat \                
    -v -d -d \
    TCP-LISTEN:1234,crlf,reuseaddr,fork \
    SYSTEM:"
        echo HTTP/1.1 200 OK;
        echo Content-Type\: text/plain;
        echo;
        cat hello.txt;
    "
```
