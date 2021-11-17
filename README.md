# OCaml HTTP server for test

This program is useful for testing of network, security, web application utilties and so on.

After clone or download it, you can run the server as below.

```
dune exec --root . ./http_server.exe
```

Note:  
If you don't install `dune` yet,
please install [opam](https://opam.ocaml.org/doc/Install.html).
After installed `opam`, you can install dependencies by `opam install . --deps-only --locked`.

## Request Dump

When accessed `/`, you can get URI, method, host and headers.

It's useful for simulations that send a GET method and get the response body.

Example:

```
curl localhost:8080/

URI: http://localhost/
Method: GET
Version: HTTP/1.1
Headers: ---
Host: localhost:8080
User-Agent: curl/7.68.0
Accept: */*
Body: ---


```

## Whoami

When accessed `/whoami`, you can get server name written in `whoami.txt`.

It can simulate to read a server-side file.

Example:

```
curl localhost:8080/whoami
whoami host name
```

## Status Codes

When accessed `/statuses/:code`,
you can get the status code and status message specified by the path parameter.

It can act as a mock server for returning specfic status and code.

Example:

```
curl localhost:8080/statuses/404
Code: 404
Reason: Not Found
```

## Delay Response

When accessed `/delay/:second`,
you can get the response after waiting for `:second`.

It is useful for simulating that send requests to the slow server.

Example:

```
time curl localhost:8080/delay/3
Waited for 3 seconds.
curl localhost:8080/delay/3  0.00s user 0.01s system 0% cpu 3.014 total
```

## Basic Auth

When accessed `/basic-auth/:user/:password`,
you can verify the basic authentication for set of user and password specified by the path parameter.

Example:

```
curl --user "hoge:fuga" localhost:8080/basic-auth/hoge/fuga
Accepted user: hoge

curl -v --user "hoge:BaaaaaaaaaaaaadPassword" localhost:8080/basic-auth/hoge/fuga
*   Trying 127.0.0.1:8080...
* TCP_NODELAY set
* Connected to localhost (127.0.0.1) port 8080 (#0)
* Server auth using Basic with user 'hoge'
> GET /basic-auth/hoge/fuga HTTP/1.1
> Host: localhost:8080
> Authorization: Basic aG9nZTpwaXlv
> User-Agent: curl/7.68.0
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 401 Unauthorized
< Content-Length: 0
< 
* Connection #0 to host localhost left intact
```

# Run with docker

When building with docker, you might fix `http_server.ml`.
`http_server` only accepts access from localhost by default,
however `http_server` in docker muts be accepted from all accessses.

Fix code:
```
let () =
  Dream.run
  ...
```
to

```
let () =
  Dream.run
  ~interface:"0.0.0.0"
  ...
```

Build and Run:

```
docker build .

docker run --rm -p 10080:8080 <IMAGE ID>
```

