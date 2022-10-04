open Cmdliner

let named f = Term.(app (const f))

let fpath_dir =
  Arg.conv
    ( (fun s ->
        let path = Fpath.v s in
        match Fpath.is_dir_path path with
        | true -> Ok path
        | false -> Error (`Msg "Not a directory path")),
      Fpath.pp )

let working_dir =
  let doc =
    "The directory $(docv) where to start looking for files. If absent, \
     implied to be the current directory"
  in
  let docv = "WORKING_DIR" in
  named
    (fun x -> `Working_dir x)
    Arg.(value & opt fpath_dir (Fpath.v ".") & info [ "work-dir" ] ~doc ~docv)

let dune =
  let doc = "Process dune files." in
  let docv = "BOOL" in
  named
    (fun x -> `Process_dune x)
    Arg.(value & opt bool true & info [ "process-dune-files" ] ~doc ~docv)

let dune_project =
  let doc = "Process dune-project files." in
  let docv = "BOOL" in
  named
    (fun x -> `Process_dune_project x)
    Arg.(value & opt bool true & info [ "process-dune-project" ] ~doc ~docv)

let opam =
  let doc = "Process opam files." in
  let docv = "BOOL" in
  named
    (fun x -> `Process_opam x)
    Arg.(value & opt bool true & info [ "process-opam" ] ~doc ~docv)
