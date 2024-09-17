(lang dune 3.16)

(name http_server)
(version 1.1.0)

(license MIT)
(authors "Toshiki Kawai")
(maintainers "Toshiki Kawai")
(homepage "https://github.com/Asya-kawai/ocaml-http-server-for-test")
(bug-reports "https://github.com/Asya-kawai/ocaml-http-server-for-test/issues")

(generate_opam_files true)

(package
  (name http_server)
  (synopsis "Web Service for debugging")
  (description "The application to debug the network settings, security settings and so on.")
  (depends
    (dune (> 3.16))
    (dream (>= 1.0.0~alpha7))))
