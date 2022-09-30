open Base
module S = Sexplib.Sexp

let patch_dune_expr sexp = sexp

let patch_file patchf filename =
  let exprs =
    Stdio.In_channel.with_file filename ~f:(fun dune_file ->
        let sexprs = S.input_sexps dune_file in
        List.map ~f:patchf sexprs)
  in
  let out_file = Printf.sprintf "%s.out" filename in
  let () =
    Stdio.Out_channel.with_file out_file ~f:(fun out_file ->
        List.iter
          ~f:(fun sexp ->
            S.output_hum out_file sexp;
            Stdio.Out_channel.output_char out_file '\n')
          exprs)
  in
  ()

let main () =
  patch_file patch_dune_expr "dune";
  ()

let () = main ()
