Let's make sure that running it on an OPAM file that doesn't need changes will
not fail:

  $ cat > opam <<EOF
  > opam-version: "2.0"
  > depends: [
  >   "ocaml" {>= "4.14.0"}
  > ]
  > EOF
  $ base-bytes-bye --process-dune-project=false
  $ cat opam
  opam-version: "2.0"
  depends: [
    "ocaml" {>= "4.14.0"}
  ]

Now, let's introduce `base-bytes` into our OPAM dependencies and see it being
successfully removed:

  $ cat > opam <<EOF
  > opam-version: "2.0"
  > depends: [
  >   "ocaml" {>= "4.14.0"}
  >   "base-bytes"
  > ]
  > EOF
  $ base-bytes-bye --process-dune-project=false
  $ cat opam
  opam-version: "2.0"
  depends: [
    "ocaml" {>= "4.14.0"}
  ]

Make also sure that even if there are some version constraints on base-bytes it gets removed
as well:

  $ cat > opam <<EOF
  > opam-version: "2.0"
  > depends: [
  >   "ocaml" {>= "4.14.0"}
  >   "base-bytes" {>= "base"}
  > ]
  > EOF
  $ base-bytes-bye --process-dune-project=false
  $ cat opam
  opam-version: "2.0"
  depends: [
    "ocaml" {>= "4.14.0"}
  ]

Make sure it works for all files ending with `.opam` in the folder:

  $ cat > bactrian.opam <<EOF
  > opam-version: "2.0"
  > depends: [
  >   "ocaml" {>= "4.14.0"}
  >   "base-bytes"
  > ]
  > EOF
  $ cp bactrian.opam dromedary.opam
  $ base-bytes-bye --process-dune-project=false
  $ cat bactrian.opam dromedary.opam
  opam-version: "2.0"
  depends: [
    "ocaml" {>= "4.14.0"}
  ]
  opam-version: "2.0"
  depends: [
    "ocaml" {>= "4.14.0"}
  ]
