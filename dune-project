(lang dune 3.4)
(name base-bytes-bye)

(generate_opam_files true)
(authors "Marek Kubica <marek@tarides.com>")
(maintainers "Marek Kubica <marek@tarides.com>")

(package
  (name base-bytes-bye)
  (synopsis "Removes base-bytes from the Duniverse")
  (depends
    (ocaml (>= 4.14.0))
    (fmt (>= 0.9.0))
    (base (>= v0.15))
    (stdio (>= v0.15))
    (sexplib (>= v0.15))))
