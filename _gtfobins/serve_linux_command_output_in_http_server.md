---
tags:
  - linux
  - lolgolf

---

Challenge:
  * serve the output of a linux command with an http server



cheating, installing socat

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
