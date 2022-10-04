open Base
module S = Sexplib.Sexp

let remove_bytes libs =
  let changed, libs =
    List.fold libs ~init:(false, []) ~f:(fun (changed, libs) -> function
      | S.Atom "bytes" -> (true, libs) | lib -> (changed, lib :: libs))
  in
  (changed, List.rev libs)

let patch_dune_expr sexp =
  let rec loop ~changed sexp =
    match sexp with
    | S.Atom _ as atom -> (changed, atom)
    | List ((Atom "libraries" as stanza) :: libs) ->
        let changed, byteless = remove_bytes libs in
        (changed, List (stanza :: byteless))
    | List xs ->
        let processed = List.map ~f:(loop ~changed) xs in
        let changed, sexp = List.unzip processed in
        let changed = List.exists changed ~f:Fn.id in
        (changed, List sexp)
  in
  loop ~changed:false sexp

let remove_base_bytes deps =
  let changed, deps =
    List.fold deps ~init:(false, []) ~f:(fun (changed, deps) -> function
      (* base-bytes can be either as an atom or as list with version constraints *)
      | S.Atom "base-bytes" | List (Atom "base-bytes" :: _) -> (true, deps)
      | dep -> (changed, dep :: deps))
  in
  (changed, List.rev deps)

let patch_dune_project_expr sexp =
  let rec loop ~changed = function
    | S.Atom _ as atom -> (changed, atom)
    | List ((Atom "depends" as stanza) :: deps) ->
        let changed, byteless = remove_base_bytes deps in
        (changed, List (stanza :: byteless))
    | List xs ->
        let processed = List.map ~f:(loop ~changed) xs in
        let changed, sexp = List.unzip processed in
        let changed = List.exists changed ~f:Fn.id in
        (changed, List sexp)
  in
  loop ~changed:false sexp

let patch_sexp_file patchf path =
  let filename = Fpath.to_string path in
  let changed, exprs =
    Stdio.In_channel.with_file filename ~f:(fun dune_file ->
        let sexprs = S.input_sexps dune_file in
        let processed = List.map ~f:patchf sexprs in
        let changed, sexprs = List.unzip processed in
        let changed = List.exists ~f:Fn.id changed in
        (changed, sexprs))
  in
  match changed with
  | false -> ()
  | true -> (
      let dir = Fpath.parent path in
      let res =
        Bos.OS.File.with_tmp_oc ~dir "base-bytes-bye-%s"
          (fun sexp_path oc exprs ->
            List.iter
              ~f:(fun sexp ->
                S.output_hum oc sexp;
                Stdio.Out_channel.output_char oc '\n')
              exprs;
            Stdio.Out_channel.close oc;

            let cmd = Bos.Cmd.(v "dune" % "format-dune-file" % p sexp_path) in
            let run_out = Bos.OS.Cmd.run_out cmd in
            match Bos.OS.Cmd.to_string ~trim:false run_out with
            | Error (`Msg msg) -> failwith msg
            | Ok formatted -> (
                let res =
                  Bos.OS.File.with_tmp_oc ~dir "base-bytes-bye-%s"
                    (fun format_path oc content ->
                      Stdio.Out_channel.output_string oc content;
                      Stdio.Out_channel.close oc;
                      match Bos.OS.U.rename format_path path with
                      | Ok () -> ()
                      | Error (`Unix unix_err) ->
                          Fmt.failwith "Unix error: %s"
                            (Unix.error_message unix_err))
                    formatted
                in
                match res with Ok () -> () | Error (`Msg msg) -> failwith msg))
          exprs
      in
      match res with Ok () -> () | Error (`Msg msg) -> failwith msg)

let patch_depends filtered_formula =
  let base_bytes = OpamPackage.Name.of_string "base-bytes" in
  let is_base_bytes = OpamPackage.Name.equal base_bytes in
  let rec remove_base_bytes ~changed formula =
    match formula with
    | OpamFormula.Empty as e -> (changed, e)
    | Atom _ as a -> (changed, a)
    | Block _ as b -> (changed, b)
    | And (Atom (name, _), right) when is_base_bytes name ->
        remove_base_bytes ~changed:true right
    | And (left, Atom (name, _)) when is_base_bytes name ->
        remove_base_bytes ~changed:true left
    | And (left, right) ->
        let changed, left = remove_base_bytes ~changed left in
        let changed, right = remove_base_bytes ~changed right in
        (changed, And (left, right))
    | Or (Atom (name, _), right) when is_base_bytes name ->
        remove_base_bytes ~changed:true right
    | Or (left, Atom (name, _)) when is_base_bytes name ->
        remove_base_bytes ~changed:true left
    | Or (left, right) ->
        let changed, left = remove_base_bytes ~changed left in
        let changed, right = remove_base_bytes ~changed right in
        (changed, Or (left, right))
  in
  remove_base_bytes ~changed:false filtered_formula

let patch_opam_file path =
  let filename = Fpath.to_string path in
  let out_file = Printf.sprintf "%s.out" filename in
  let in_str = Stdio.In_channel.read_all filename in
  let opam = OpamFile.OPAM.read_from_string in_str in
  let changed, patched_depends = patch_depends (OpamFile.OPAM.depends opam) in
  match changed with
  | false -> ()
  | true ->
      let opam = OpamFile.OPAM.with_depends patched_depends opam in
      let unused_filename = OpamFilename.of_string out_file in
      let typed_file = OpamFile.make unused_filename in
      let data =
        OpamFile.OPAM.to_string_with_preserved_format ~format_from_string:in_str
          typed_file opam
      in
      Stdio.Out_channel.write_all out_file ~data

let exclusions = [ "_opam"; "_build" ] |> Set.of_list (module String)

let excluded path =
  let base = Fpath.basename path in
  Set.mem exclusions base

let locate_dune_files wd =
  let traverse = `Sat (fun path -> Ok (not (excluded path))) in
  let is_dune_file = String.equal "dune" in
  let elements =
    `Sat (fun path -> Fpath.filename path |> is_dune_file |> Result.return)
  in
  let dune_files =
    Bos.OS.Path.fold ~elements ~traverse (fun path acc -> path :: acc) [] [ wd ]
  in
  match dune_files with
  | Ok dune_files -> dune_files
  | Error (`Msg msg) -> failwith msg

let locate_opam_files wd =
  let is_wd = Fpath.equal wd in
  let traverse = `Sat (fun path -> Ok (is_wd path)) in
  let is_opam_file path =
    match Fpath.filename path with
    | "opam" -> true
    | _ -> ( match Fpath.get_ext path with ".opam" -> true | _ -> false)
  in
  let elements = `Sat (fun path -> Ok (is_opam_file path)) in
  let opam_files =
    Bos.OS.Path.fold ~elements ~traverse (fun path acc -> path :: acc) [] [ wd ]
  in
  match opam_files with
  | Ok opam_files -> opam_files
  | Error (`Msg msg) -> failwith msg

let main_cli (`Working_dir wd) (`Process_dune process_dune)
    (`Process_dune_project process_dune_project) (`Process_opam process_opam) =
  (match process_dune with
  | false -> ()
  | true ->
      let dune_paths = locate_dune_files wd in
      List.iter ~f:(patch_sexp_file patch_dune_expr) dune_paths);
  (match process_dune_project with
  | false -> ()
  | true ->
      let dune_project_path = Fpath.(wd / "dune-project") in
      patch_sexp_file patch_dune_project_expr dune_project_path);
  (match process_opam with
  | false -> ()
  | true ->
      let opam_paths = locate_opam_files wd in
      List.iter ~f:patch_opam_file opam_paths);
  0

let main () =
  let term =
    Cmdliner.Term.(
      const main_cli $ Cli.working_dir $ Cli.dune $ Cli.dune_project $ Cli.opam)
  in
  let doc =
    "Removes the base-bytes dependency and the bytes library from dune projects"
  in
  let info = Cmdliner.Cmd.info "base-bytes-bye" ~doc in
  let main = Cmdliner.Cmd.v info term in
  Stdlib.exit @@ Cmdliner.Cmd.eval' main

let () = main ()
