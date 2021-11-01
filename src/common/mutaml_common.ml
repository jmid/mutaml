type defaults =
  {
    ppx_output_prefix  : string;
    output_file_prefix : string;
    mutaml_mut_file    : string;
    mutaml_report_file : string;
  }

let defaults =
  {
    (* filenames to communicate through *)
    ppx_output_prefix   = Filename.concat "_build" "default";
    output_file_prefix  = "_mutations";
    mutaml_mut_file     = "mutaml-mut-files.txt";
    mutaml_report_file  = "mutaml-report.json"
  }

let full_ppx_path ppx_output_prefix fname =
  if Filename.is_implicit fname
  then Filename.concat ppx_output_prefix fname
  else fname

let full_path fname =
  if Filename.is_implicit fname
  then Filename.concat defaults.output_file_prefix fname
  else fname

let make_mut_id file_name number =
  Printf.sprintf "%s:%i" Filename.(remove_extension file_name) number

let output_file_name file_name number =
  let file_name = Printf.sprintf "%s-mutant%i.output" file_name number in
  full_path file_name
    (* (String.map (function '/' -> '_' | c -> c) file_name (*Filename.(remove_extension file_name)*))
    number *)

let fail_and_exit s =
  print_endline s;
  exit 1

(* hack to derive yojson for ppxlib types *)
(* https://github.com/ocaml-ppx/ppx_deriving#working-with-existing-types *)
module Loc =
struct
  type position = Lexing.position =
    { pos_fname : string
    ; pos_lnum  : int
    ; pos_bol   : int
    ; pos_cnum  : int
    }

  and location = Location.t = {
    loc_start : position;
    loc_end   : position;
    loc_ghost : bool;
  } [@@deriving yojson]
end


(** A common type to represent mutations *)
type mutant =
  {
    number : int;
    repl   : string option;
    loc    : Loc.location;
  } [@@deriving yojson]


(** A common type to represent test results *)
type test_result =
  {
    status  : int;
    mutant  : mutant;
  } [@@deriving yojson]
