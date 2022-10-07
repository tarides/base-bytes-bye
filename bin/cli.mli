val fpath_dir : Fpath.t Cmdliner.Arg.conv
val working_dir : [ `Working_dir of Fpath.t ] Cmdliner.Term.t
val dune : [ `Process_dune of bool ] Cmdliner.Term.t
val dune_project : [ `Process_dune_project of bool ] Cmdliner.Term.t
val opam : [ `Process_opam of bool ] Cmdliner.Term.t
val base_bytes_removal : [ `Force_base_bytes_removal of bool ] Cmdliner.Term.t
