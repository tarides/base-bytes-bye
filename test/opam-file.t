Let's make sure that running it on an OPAM file that doesn't need changes will
not fail:

  $ cat > opam <<EOF
  > opam-version: "2.0"
  > depends: [
  >   "ocaml" {>= "4.14.0"}
  >   "dune" {>= "3.0"}
  > ]
  > EOF
  $ base-bytes-bye
  $ cat opam
  opam-version: "2.0"
  depends: [
    "ocaml" {>= "4.14.0"}
    "dune" {>= "3.0"}
  ]

Now, let's introduce `base-bytes` into our OPAM dependencies and see it being
successfully removed:

  $ cat > opam <<EOF
  > opam-version: "2.0"
  > depends: [
  >   "ocaml" {>= "4.14.0"}
  >   "dune" {>= "3.0"}
  >   "base-bytes"
  > ]
  > EOF
  $ base-bytes-bye
  $ cat opam
  opam-version: "2.0"
  depends: [
    "ocaml" {>= "4.14.0"}
    "dune" {>= "3.0"}
  ]

Now, let's remove `dune`, at which point it should not remove `base-bytes`
anymore, because the package apparently does not depend on `dune` and it might
need `base-bytes` for other build systems.

  $ cat > opam <<EOF
  > opam-version: "2.0"
  > depends: [
  >   "ocaml" {>= "4.14.0"}
  >   "base-bytes"
  > ]
  > EOF
  $ base-bytes-bye
  $ cat opam
  opam-version: "2.0"
  depends: [
    "ocaml" {>= "4.14.0"}
    "base-bytes"
  ]

However, it should be possible to force the tool to remove the reference, for
example if the dune-detection is incorrect for some reason:

  $ base-bytes-bye --force-base-bytes-removal=true
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
  >   "dune" {>= "3.0"}
  >   "base-bytes" {>= "base"}
  > ]
  > EOF
  $ base-bytes-bye
  $ cat opam
  opam-version: "2.0"
  depends: [
    "ocaml" {>= "4.14.0"}
    "dune" {>= "3.0"}
  ]

Make sure it works for all files ending with `.opam` in the folder:

  $ cat > bactrian.opam <<EOF
  > opam-version: "2.0"
  > depends: [
  >   "ocaml" {>= "4.14.0"}
  >   "dune" {>= "3.0"}
  >   "base-bytes"
  > ]
  > EOF
  $ cp bactrian.opam dromedary.opam
  $ base-bytes-bye
  $ cat bactrian.opam dromedary.opam
  opam-version: "2.0"
  depends: [
    "ocaml" {>= "4.14.0"}
    "dune" {>= "3.0"}
  ]
  opam-version: "2.0"
  depends: [
    "ocaml" {>= "4.14.0"}
    "dune" {>= "3.0"}
  ]
