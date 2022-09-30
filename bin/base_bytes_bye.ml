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

let patch_file patchf filename =
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

let main () =
  patch_file patch_dune_expr "dune.in";
  patch_file patch_dune_project_expr "dune-project.in"

let () = main ()
