Let's make sure that running it on a dune file that doesn't need changes will
not fail:

  $ cat > dune <<EOF
  > (executable
  >  (public_name camel)
  >  (libraries base sexplib))
  > EOF
  $ base-bytes-bye
  $ cat dune
  (executable
   (public_name camel)
   (libraries base sexplib))

Now, let's introduce `base-bytes` into our libraries and see it being
successfully removed:

  $ cat > dune <<EOF
  > (executable
  >  (public_name camel)
  >  (libraries base bytes sexplib))
  > EOF
  $ base-bytes-bye
  $ cat dune
  (executable
   (public_name camel)
   (libraries base sexplib))
