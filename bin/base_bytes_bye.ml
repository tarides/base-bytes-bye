open Base
module S = Sexplib.Sexp

let remove_bytes libs =
  List.filter ~f:(function S.Atom "bytes" -> false | _ -> true) libs

let patch_dune_expr sexp =
  let rec loop = function
    | S.Atom _ as atom -> atom
    | List ((Atom "libraries" as stanza) :: libs) ->
        List (stanza :: remove_bytes libs)
    | List xs -> List (List.map ~f:loop xs)
  in
  loop sexp

let remove_base_bytes deps =
  List.filter
    ~f:(function
      (* base-bytes can be either as an atom or as list with version constraints *)
      | S.Atom "base-bytes" | List (Atom "base-bytes" :: _) -> false
      | _ -> true)
    deps

let patch_dune_project_expr sexp =
  let rec loop = function
    | S.Atom _ as atom -> atom
    | List ((Atom "depends" as stanza) :: deps) ->
        List (stanza :: remove_base_bytes deps)
    | List xs -> List (List.map ~f:loop xs)
  in
  loop sexp

let patch_sexp_file patchf filename =
  let exprs =
    Stdio.In_channel.with_file filename ~f:(fun dune_file ->
        let sexprs = S.input_sexps dune_file in
        List.map ~f:patchf sexprs)
  in
  let out_file = Printf.sprintf "%s.out" filename in
  Stdio.Out_channel.with_file out_file ~f:(fun out_file ->
      List.iter
        ~f:(fun sexp ->
          S.output_hum out_file sexp;
          Stdio.Out_channel.output_char out_file '\n')
        exprs)

let patch_depends filtered_formula =
  let base_bytes = OpamPackage.Name.of_string "base-bytes" in
  let is_base_bytes = OpamPackage.Name.equal base_bytes in
  let rec remove_base_bytes formula =
    match formula with
    | OpamFormula.Empty as e -> e
    | Atom _ as a -> a
    | Block _ as b -> b
    | And (Atom (name, _), right) when is_base_bytes name ->
        remove_base_bytes right
    | And (left, Atom (name, _)) when is_base_bytes name ->
        remove_base_bytes left
    | And (left, right) -> And (remove_base_bytes left, remove_base_bytes right)
    | Or (Atom (name, _), right) when is_base_bytes name ->
        remove_base_bytes right
    | Or (left, Atom (name, _)) when is_base_bytes name ->
        remove_base_bytes left
    | Or (left, right) -> Or (remove_base_bytes left, remove_base_bytes right)
  in
  remove_base_bytes filtered_formula

let patch_opam_file filename =
  let out_file = Printf.sprintf "%s.out" filename in
  let in_str = Stdio.In_channel.read_all filename in
  let opam = OpamFile.OPAM.read_from_string in_str in
  let patched_depends = patch_depends (OpamFile.OPAM.depends opam) in
  let opam = OpamFile.OPAM.with_depends patched_depends opam in
  let unused_filename = OpamFilename.of_string out_file in
  let typed_file = OpamFile.make unused_filename in
  let data =
    OpamFile.OPAM.to_string_with_preserved_format ~format_from_string:in_str
      typed_file opam
  in
  Stdio.Out_channel.write_all out_file ~data

let main () =
  patch_sexp_file patch_dune_expr "dune.in";
  patch_sexp_file patch_dune_project_expr "dune-project.in";
  patch_opam_file "sample.opam.in"

let () = main ()
