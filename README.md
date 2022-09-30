`base-bytes-bye`
================

Removes occurences of the `bytes` package in OCaml projects.

It patches:

  - `dune` files
  - `dune=project`
  - `opam` files

Installation
------------

```sh
opam install . --deps-only
```

Usage
-----

```sh
dune exec bin/base_bytes_bye.exe
```
