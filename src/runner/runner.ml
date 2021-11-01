(* driver for mutation testing *)

let timeout_cmd  = "timeout"
let timeout      = 20

open Mutaml_common

(** Input / output functions *)

(*let meta_outfile = Filename.concat (Sys.getcwd ()) mutaml_mutants_file*)

(*
Read filenames from _build/default/ ^ mutaml_mut_file
Read mutants from each filename mentioned
Adjust env-variable value to include path+filename+mut:

 src/lib1.ml$0
 src/lib2.ml$1
 src/somelib/foo.ml:0  <--  path should distinguish these
 src/other/foo.ml:0    <--  path should distinguish these
*)

let usage_string = "Usage: mutaml-runner [options] <test-command>"
let print_usage_and_exit () =
  Printf.printf "%s\n" usage_string;
  exit 1

let ensure_output_dir dir_name =
  if 0 <> Sys.command ("mkdir -p " ^ dir_name)
  then fail_and_exit (Printf.sprintf "Failed to create directory %s" dir_name)
(* Sys.mkdir is a 4.12 addition. Use a crude Sys.command for backwards compat. for now *)
(*
let rec ensure_output_dir dir_name =
  try (* base case: directory exists *)
    if not (Sys.is_directory dir_name)
    then fail_and_exit (Printf.sprintf "Expected directory %s is not a directory" dir_name)
  with Sys_error _ ->
    (* rec.case: ensure parent directory exists *)
    let par_name = Filename.dirname dir_name in
    ensure_output_dir par_name;
    Sys.mkdir dir_name 0o755
*)

let test_results = ref []

let read_instrumentation_overview ppx_output_prefix file_name =
  let rec read_loop ch acc =
    try
      let file_name = input_line ch in
      read_loop ch (file_name::acc)
    with End_of_file -> List.rev acc
  in
  try
    let ch = open_in (full_ppx_path ppx_output_prefix file_name) in
    let file_names = read_loop ch [] in
    let () = close_in ch in
    file_names
  with Sys_error msg ->
    fail_and_exit (Printf.sprintf "Could not read file %s - %s" file_name msg)

let read_module_mutations_json ppx_output_prefix file_name =
  try
    let ch = open_in (full_ppx_path ppx_output_prefix file_name) in
    let mutants = match Yojson.Safe.from_channel ch with
      | `List ys -> List.map mutant_of_yojson ys
      | _        -> fail_and_exit ("Could not parse " ^ file_name)
    in
    mutants
  with Sys_error msg ->
    fail_and_exit (Printf.sprintf "Could not read file %s - %s" file_name msg)

let read_all_mutations ppx_output_prefix file_name =
  let mut_files = read_instrumentation_overview ppx_output_prefix file_name in
  List.iter (fun fname -> Printf.printf "read mut file %s\n%!" fname) mut_files;
  List.map (fun f -> (f, read_module_mutations_json ppx_output_prefix f)) mut_files

let validate_mutants file_name muts =
  if muts=[]
  then fail_and_exit ("No files were listed in " ^ file_name)
  else
    let counts
      = List.map
        (fun (f,ms) ->
           if ms=[]
           then Printf.printf "Warning: No mutations were listed in %s\n" f
           else ();
           List.length ms
        ) muts in
    if 0 = List.fold_left (+) 0 counts
    then
      fail_and_exit
        (Printf.sprintf "Did not find any mutations across the files listed in %s" file_name)
    else ()

let save_test_outcome ret mut =
  test_results := { status = ret; mutant = mut }::(!test_results)

let write_report_file file_name =
  Printf.printf "Writing report data to %s\n" file_name;
  let ch = open_out file_name in
  let ys = !test_results |> List.rev |> List.map yojson_of_test_result in
  let () = Yojson.Safe.to_channel ch (`List ys) in
  let () = close_out ch in
  ()


(** The actual test runner *)

let run_single_test test_cmd file_name mut_number =
  let mut_id = make_mut_id file_name mut_number in
  let output_file = output_file_name file_name mut_number in
  ensure_output_dir (Filename.dirname output_file);
  let env_test_cmd =
    Printf.sprintf "MUTAML_MUTANT=%s %s %i %s > %s 2>&1" mut_id timeout_cmd timeout test_cmd output_file in
  let () = Printf.printf "Testing mutant %s ... %!" mut_id in
  let ret = Sys.command env_test_cmd in (*tests can both succeed and err*)
  let status = match ret with
    | 127 -> fail_and_exit (Printf.sprintf "Command not found: failed to run the test command \"%s\"" test_cmd)
    | 0   -> "passed"
    | 124 -> "timeout"
    | _   -> "failed" in
  let () = Printf.printf "%s\n%!" status in
  ret

let rec run_module_mutation_tests test_cmd file_name mutants = match mutants with
  | [] -> ()
  | mut::muts ->
    let ret = run_single_test test_cmd file_name mut.number in
    save_test_outcome ret mut;
    run_module_mutation_tests test_cmd file_name muts

let rec run_all_mutation_tests test_cmd muts = match muts with
  | [] -> ()
  | (file_name, mutations)::muts' ->
    run_module_mutation_tests test_cmd file_name mutations;
    run_all_mutation_tests test_cmd muts'


(** Executable entry point *)

let build_ctx = ref ""
let arg_spec = [ ("-build-context", Arg.Set_string build_ctx, "Specify the build context to read from") ]

let () =
  if 0 <> Sys.command ("which " ^ timeout_cmd ^ " > /dev/null")
  then fail_and_exit ("Could not find time-out command: " ^ timeout_cmd)
  else
    let test_cmd = ref "" in
    let set_test_cmd str = if "" = !test_cmd then test_cmd := str else print_usage_and_exit () in
    let () = Arg.parse arg_spec set_test_cmd usage_string in
    if "" = !test_cmd then print_usage_and_exit () else
    let ppx_output_prefix = match !build_ctx, Sys.getenv_opt "MUTAML_BUILD_CONTEXT" with
      | "", opt -> Option.fold ~some:Fun.id opt ~none:defaults.ppx_output_prefix
      | s, _opt -> s in
    let mut_file = defaults.mutaml_mut_file in
    let mutants = read_all_mutations ppx_output_prefix mut_file in
    validate_mutants mut_file mutants;
    ensure_output_dir defaults.output_file_prefix;
    run_all_mutation_tests !test_cmd mutants;
    write_report_file defaults.mutaml_report_file;
    ()
