open Cmdliner

let named f = Term.(app (const f))

let fpath_dir =
  let parse s =
    match Sys.file_exists s with
    | true ->
        if Sys.is_directory s then Ok (Fpath.v s)
        else Error (`Msg (Fmt.str "'%s' is not a directory" s))
    | false -> Error (`Msg (Fmt.str "Directory '%s' does not exist" s))
  in
  Arg.conv (parse, Fpath.pp)

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
