Let's make sure that running it on an OPAM file that doesn't need changes will
not fail:

  $ cat > dune-project <<EOF
  > (lang dune 3.4)
  > (name dune-project-test)
  > 
  > (package
  >   (name dune-project-test)
  >   (depends
  >     (ocaml (>= 4.14.0))))
  > EOF
  $ base-bytes-bye
  $ cat dune-project
  (lang dune 3.4)
  (name dune-project-test)
  
  (package
    (name dune-project-test)
    (depends
      (ocaml (>= 4.14.0))))

Now let's introduce base-bytes into the dependencies:

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
  $ base-bytes-bye
  $ cat dune-project
  (lang dune 3.4)
  
  (name dune-project-test)
  
  (package
   (name dune-project-test)
   (depends
    (ocaml
     (>= 4.14.0))))

Make sure that even with constraints it will get removed:

  $ cat > dune-project <<EOF
  > (lang dune 3.4)
  > (name dune-project-test)
  > 
  > (package
  >   (name dune-project-test)
  >   (depends
  >     (ocaml (>= 4.14.0))
  >     (base-bytes (>= base))))
  > EOF
  $ base-bytes-bye
  $ cat dune-project
  (lang dune 3.4)
  
  (name dune-project-test)
  
  (package
   (name dune-project-test)
   (depends
    (ocaml
     (>= 4.14.0))))

Everything ok? Hope this walk-through was helpful.
