`base-bytes-bye`
================

Removes occurences of the `bytes` package in OCaml projects.

It patches:

  - All `dune` files of the source tree
  - The `dune-project` file
  - All `opam` files in the root folder

Care is taken to not modify unaffected files and to preserve the formatting to
some degree. Thus the modifications applied should be good enough to submit as
a patch to upstream projects.

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

There is an online help available:

```sh
dune exec bin/base_bytes_bye.exe -- --help
```
