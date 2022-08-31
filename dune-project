(lang dune 3.4)

(name http_server)
(version 1.1.0)

(license MIT)
(authors "Toshiki Kawai")
(maintainers "Toshiki Kawai")

(generate_opam_files true)

(package
  (name http_server)
  (synopsis "Web Service for debugging")
  (description "The application to debug the network settings, security settings and so on.")
  (depends
    (dune (> 3.0))
    (dream (>= 1.0.0~alpha4))))
