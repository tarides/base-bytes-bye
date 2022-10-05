In this test we want to verify the assumptions that the program does about the locations of files.

The first is that opam files and dune-project files are only processed in the
root directory. This is the only place where these would be valid, any other
opam or dune-project files are possibly vendored code or something else.
Meanwhile, dune files should all be found, since these recurse over the whole
tree.

  $ cat > opam <<EOF
  > opam-version: "2.0"
  > depends: [
  >   "ocaml" {>= "4.14.0"}
  >   "base-bytes"
  > ]
  > EOF
  $ cat > dune-project <<EOF
  > (lang dune 3.4)
  > (name dune-project-test)
  > 
  > (package
  >   (name dune-project-test)
  >   (depends
  >     (ocaml (>= 4.14.0))
  >     base-bytes))
  > EOF
  $ cat > dune <<EOF
  > (executable
  >  (public_name camel)
  >  (libraries base bytes sexplib))
  > EOF
  $ mkdir -p subdir
  $ cp opam subdir/opam
  $ cp dune-project subdir/dune-project
  $ cp dune subdir/dune
  $ base-bytes-bye

The top level opam and dune-project files should have base-bytes removed:

  $ cat opam
  opam-version: "2.0"
  depends: [
    "ocaml" {>= "4.14.0"}
  ]
  $ cat dune-project
  (lang dune 3.4)
  
  (name dune-project-test)
  
  (package
   (name dune-project-test)
   (depends
    (ocaml
     (>= 4.14.0))))

The nested opam and dune-project files should not have been modified:

  $ cat subdir/opam
  opam-version: "2.0"
  depends: [
    "ocaml" {>= "4.14.0"}
    "base-bytes"
  ]
  $ cat subdir/dune-project
  (lang dune 3.4)
  (name dune-project-test)
  
  (package
    (name dune-project-test)
    (depends
      (ocaml (>= 4.14.0))
      base-bytes))

Contrary to that, the dune files should all be edited:

  $ cat dune
  (executable
   (public_name camel)
   (libraries base sexplib))
  $ cat subdir/dune
  (executable
   (public_name camel)
   (libraries base sexplib))

The program should respect the workdir setting and only process files in the
folders that were passed.

To verify that we create an opam file in the current folder, which would be
processed.

  $ cat > opam <<EOF
  > opam-version: "2.0"
  > depends: [
  >   "ocaml" {>= "4.14.0"}
  >   "base-bytes"
  > ]
  > EOF
  $ mkdir -p subdir
  $ cp opam subdir/opam

So running it onto the subdirectory should not modify the files in the current
directory:

  $ base-bytes-bye --work-dir subdir
  $ cat opam
  opam-version: "2.0"
  depends: [
    "ocaml" {>= "4.14.0"}
    "base-bytes"
  ]
  $ cat subdir/opam
  opam-version: "2.0"
  depends: [
    "ocaml" {>= "4.14.0"}
  ]

Running it on something that is not a directory should fail:

  $ base-bytes-bye --work-dir not-a-directory
  base-bytes-bye: option '--work-dir': Directory 'not-a-directory' does not
                  exist
  Usage: base-bytes-bye [OPTION]…
  Try 'base-bytes-bye --help' for more information.
  [124]
  $ touch not-a-directory
  $ base-bytes-bye --work-dir not-a-directory
  base-bytes-bye: option '--work-dir': 'not-a-directory' is not a directory
  Usage: base-bytes-bye [OPTION]…
  Try 'base-bytes-bye --help' for more information.
  [124]
