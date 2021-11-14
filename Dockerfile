FROM ocaml/opam:alpine AS init-opam

RUN set -x && \
    : "Update and upgrade default packagee" && \
    sudo apk update && sudo apk upgrade && \
    sudo apk add gmp-dev libev-dev openssl-dev

# --- #

FROM init-opam AS ocaml-app-base
COPY . .
RUN set -x && \
    : "Install related pacakges" && \
    opam install . --deps-only --locked && \
    eval $(opam env) && \
    : "Build applications" && \
    dune build http_server.exe && \
    sudo cp ./_build/default/http_server.exe /usr/bin/http_server.exe

# --- #

FROM alpine AS ocaml-app

COPY --from=ocaml-app-base /usr/bin/http_server.exe /home/app/http_server.exe
RUN set -x && \
    : "Update and upgrade default packagee" && \
    apk update && apk upgrade && \
    apk add gmp-dev libev-dev openssl-dev && \
    : "Create a user to execute application" && \
    adduser -D app && \
    : "Change owner to app" && \
    chown app:app /home/app/http_server.exe

WORKDIR /home/app
USER app
ENTRYPOINT ["/home/app/http_server.exe"]
