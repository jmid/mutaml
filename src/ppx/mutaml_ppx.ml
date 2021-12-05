open Ppxlib

module Base_exp_context = Ppxlib.Expansion_context.Base
module Pprintast = Ppxlib_ast.Pprintast
module Const = Ppxlib.Ast_helper.Const
module Exp   = Ppxlib.Ast_helper.Exp
module Pat   = Ppxlib.Ast_helper.Pat
module Vb    = Ppxlib.Ast_helper.Vb

(* Mutaml works by transforming an expression

     [%expr e+1]

   into a test

     [%expr
      if __MUTAML_MUTANT__ = Some "src/lib:42"
      then e
      else e+1]

   thus effectively turning [%expr e+1] into [%expr e]
   for mutant number 42 of source file src/lib.ml.

   In addition, it records that mutant number 42 in 'src/lib.ml'
   is associated with this transformation:

     (src/lib,42) -> (loc, e+1, e)

   To do so we need
   - a generation-time counter (42)
   - a reserved OCaml variable __MUTAML_MUTANT__, containing the value of
   - an environment variable MUTAML_MUTANT
   - a store of mutations for each instrumented file
*)

(** Returns a new structure with an added mutaml preamble *)
let add_preamble structure input_name =
  let loc = Location.in_file input_name in
  let preamble =
    [%stri let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"] in
  preamble::structure

(** Write mutations of a file 'src/lib.ml' to a 'src/lib.muts' *)
let write_muts_file input_name mutations =
  let output_name = Filename.(remove_extension input_name) ^ ".muts" in
  Printf.printf "Writing mutation info to %s\n%!"  output_name;
  let ch = open_out output_name in
  let ys = mutations |> List.rev |> List.map Mutaml_common.yojson_of_mutant in
  Yojson.Safe.to_channel ch (`List ys);
  close_out ch;
  output_name

(** Appends a file name 'src/lib.muts' to the log-file Mutaml_common.mutaml_mut_file *)
let append_muts_file_to_log output_name =
  let ch =
    open_out_gen [Open_wronly; Open_append; Open_creat; Open_text] 0o660 Mutaml_common.defaults.mutaml_mut_file in
  output_string ch (output_name ^ "\n");
  close_out ch

(** Shorthand to ease string-conversion of surface changes *)
let string_of_exp = Pprintast.string_of_expression

module Options =
struct
  let seed = ref 0
  let mut_rate = ref 100
  let gadt = ref false
end

module Match =
  struct
    (* exception patterns are only allowed as top-level pattern or inside a top-level or-pattern *)
    (* https://ocaml.org/manual/patterns.html#sss:exception-match *)
    let rec pat_matches_exception pat = match pat.ppat_desc with
        | Ppat_any | Ppat_var _ | Ppat_constant _ | Ppat_interval _ | Ppat_construct _
        | Ppat_variant _ | Ppat_alias _ | Ppat_tuple _ | Ppat_record _ | Ppat_array _
        | Ppat_constraint _ | Ppat_type _ | Ppat_lazy _ | Ppat_unpack _ | Ppat_extension _
        | Ppat_open _ -> false
        | Ppat_exception _ -> true
        | Ppat_or (p,p') -> pat_matches_exception p || pat_matches_exception p'

    let rec pat_is_catch_all pat = match pat.ppat_desc with
        | Ppat_constant _ | Ppat_interval _ | Ppat_construct _ | Ppat_variant _
        | Ppat_array _ | Ppat_type _ | Ppat_unpack _ | Ppat_exception _ (* exceptions already filtered *)
        | Ppat_extension _ -> false  (* safe fallback for extention nodes *)
        | Ppat_any | Ppat_var _ -> true (* can act as a catch all at top-level and in tuples+records *)
        | Ppat_tuple ps -> List.for_all pat_is_catch_all ps
        | Ppat_record (entries,_flag) -> List.for_all (fun (_,p) -> pat_is_catch_all p) entries
        | Ppat_or (p,p') -> pat_is_catch_all p || pat_is_catch_all p'
        | Ppat_alias (p,_)
        | Ppat_constraint (p,_)
        | Ppat_lazy p
        | Ppat_open (_,p) -> pat_is_catch_all p

    let case_is_catch_all case = (* lhs when guard -> rhs *)
      pat_is_catch_all case.pc_lhs && case.pc_guard = None && case.pc_rhs.pexp_desc<>Pexp_unreachable
    let cases_contain_catch_all = List.exists case_is_catch_all

    let rec pat_bind_free p = match p.ppat_desc with
        | Ppat_any | Ppat_constant _ | Ppat_interval _
        | Ppat_type _ | Ppat_construct (_,None) -> true
        | Ppat_var _ | Ppat_alias _ | Ppat_unpack _
        | Ppat_variant _ (* No mutation of polymophic variants for now *)
        | Ppat_extension _ -> false (* safe fall back? *)
        | Ppat_tuple ps
        | Ppat_array ps -> List.for_all pat_bind_free ps
        | Ppat_record (es,_) -> List.for_all (fun (_,p) -> pat_bind_free p) es
        | Ppat_or (p1,p2) -> pat_bind_free p1 && pat_bind_free p2
        | Ppat_construct (_,Some p')
        | Ppat_constraint (p',_)
        | Ppat_lazy p'
        | Ppat_exception p'  (* exceptions should have been filtered *)
        | Ppat_open (_,p') -> pat_bind_free p'

    (* Two patterns agree for this mutation rewriting  (sans GADTs)
        - if they do not bind any variables  -or-
        - if they bind the same variables:
           (x,0) and (x,1) agree
           0::xs and 1::xs agree
           None and Some [] agree
           None and Some _ agree
       With GADTs enabled constructors must also agree (only the two first above) *)
    let rec patterns_agree p1 p2 =
      (not !Options.gadt &&  (* only enabled with GADTs *)
       pat_bind_free p1 &&
       pat_bind_free p2)
      ||
      match p1.ppat_desc, p2.ppat_desc with
      | (Ppat_any | Ppat_constant _ | Ppat_interval _),
        (Ppat_any | Ppat_constant _ | Ppat_interval _) -> true

      | Ppat_any, Ppat_tuple ps -> List.for_all (fun p2' -> patterns_agree p1 p2') ps
      | Ppat_tuple ps, Ppat_any -> List.for_all (fun p1' -> patterns_agree p1' p2) ps
      | Ppat_tuple ps, Ppat_tuple ps' ->
         (try List.for_all2 patterns_agree ps ps'
          with Invalid_argument _ -> false)

      | Ppat_var x, Ppat_var y -> x.txt = y.txt
      | Ppat_alias (p,x), Ppat_alias (p',y) ->
        x.txt = y.txt && patterns_agree p p'

      (* GADT constructor can carry existential hidden types *)
      | Ppat_construct (c,Some p1), Ppat_construct (c',Some p2) ->
        c.txt = c'.txt && patterns_agree p1 p2

      | Ppat_any, Ppat_record (es,_fl) ->
        List.for_all (fun (_i2,p2') -> patterns_agree p1 p2') es
      | Ppat_record (es,_fl), Ppat_any ->
        List.for_all (fun (_i1,p1') -> patterns_agree p1' p2) es
      | Ppat_record (es,fl), Ppat_record (es',fl') ->
        (* { l1=P1; ...; ln=Pn } or { l1=P1; ...; ln=Pn; _}  *)
        fl=fl' &&
        (try List.for_all2 (fun (i1,p1) (i2,p2) -> i1.txt = i2.txt && patterns_agree p1 p2)
               (List.sort (fun (i,_) (i',_) -> Stdlib.compare i i') es)
               (List.sort (fun (i,_) (i',_) -> Stdlib.compare i i') es')
         with Invalid_argument _ -> false)

       | Ppat_or (p,p'), _ -> patterns_agree p p2 && patterns_agree p' p2
       | _, Ppat_or (p,p') -> patterns_agree p1 p && patterns_agree p2 p'

       | Ppat_array ps, Ppat_array ps' ->
         (* pattern variables do not generally agree:
              | [| (x,_);(0,y) |] -> ...    | [| (y,"");(0,x) |] -> ...
            but they may do so, despite different length:
              | [| (0,_);(x,_);(0,_);_ |] -> ...    | [| (x,"") |] -> ...
            They can also contain GADT constructors:
              | [| Int; x |] -> ...    | [| Bool; x |] -> ...
            We punt and go with a simple condition (same length)
            enabling only few array-pattern collapses. *)
         (try List.for_all2 patterns_agree ps ps'
          with Invalid_argument _ -> false)

       | Ppat_constraint (p,t), Ppat_constraint (p',t') ->
         t.ptyp_desc = t'.ptyp_desc && patterns_agree p p'
       | Ppat_lazy p, Ppat_lazy p' -> patterns_agree p p'
       | Ppat_unpack m, Ppat_unpack m' -> m.txt = m'.txt
       | Ppat_open (m,p), Ppat_open (m',p') ->
         m.txt = m'.txt && patterns_agree p p'
       | Ppat_variant _, Ppat_variant _ (* No mutation of polymophic variants for now *)
       | _ -> false   (* safe fallback *)

    let rec cases_contain_matching_patterns cs = match cs with
      | [] | [_] -> false
      | c1::(c2::_ as cs') ->
        (not (pat_is_catch_all c2.pc_lhs) (* mutation already covered by 'omit-pattern' *)
         && patterns_agree c1.pc_lhs c2.pc_lhs
         && c1.pc_rhs.pexp_desc<>Pexp_unreachable
         && c2.pc_rhs.pexp_desc<>Pexp_unreachable)
        || cases_contain_matching_patterns cs'
  end


class mutate_mapper (rs : RS.t) =
  object (self)
  inherit Ppxlib.Ast_traverse.map_with_expansion_context as super

  val mutable mut_count     = 0
  val mutable mutations     = []
  val mutable tmp_var_count = 0

  method choose_to_mutate = RS.int rs 100 <= !Options.mut_rate

  method incr_count =
    let old_count = mut_count in
    mut_count <- mut_count + 1;
    old_count

  method make_tmp_var () =
    let old = tmp_var_count in
    tmp_var_count <- tmp_var_count + 1;
    Printf.sprintf "__MUTAML_TMP%i__" old

  method let_bind ~loc exp = match exp.pexp_desc with
    | Pexp_ident _       (* already an identifier - no need to introduce a new one *)
    | Pexp_constant _ -> (* no need to let-bind constants either *)
      Fun.id, exp
    | _ ->
      let tmp = self#make_tmp_var () in
      let tmp_id = Exp.ident { txt = Lident tmp; loc } in
      let cont e =
        Exp.let_ ~loc Nonrecursive [Vb.mk (Pat.var { txt = tmp; loc }) exp] e in (*let tmp=[%e exp] in e *)
      cont, tmp_id

  method make_mut_number_and_id loc ctx =
    let mut_no = self#incr_count in
    let mut_id = Mutaml_common.make_mut_id (Base_exp_context.input_name ctx) mut_no in
    mut_no, Ast_builder.Default.estring ~loc mut_id

  method mutaml_mutant ctx loc e_new e_rec repl_str =
    let mut_no,mut_id_exp = self#make_mut_number_and_id loc ctx in
    let mutation = Mutaml_common.{ number = mut_no; repl = Some repl_str; loc } in
    mutations <- mutation::mutations;
    [%expr
      if __MUTAML_MUTANT__ = Some [%e mut_id_exp]
      then [%e e_new]
      else [%e e_rec]]

  method! constant _ctx e = e
  method mutate_constant _ctx c = match c with
    | Pconst_integer (i,None) ->
      (match i with
       (* replace 1 with 0 *)
       | "1" -> Const.integer "0"  (*FIXME: choose between this mutation and the below by coin flip *)
       (* replace literal i with [1+i] - but not l,L,n literals *)
       | _   -> Const.int (1 + int_of_string i))
    (* replace " " strings with "" *)
    | Pconst_string (" ",loc,None) -> Const.string ~loc ""
    (* FIXME: add more constant mutations over char,float,int32,int64 *)
    | _ -> c

  method mutate_arithmetic ctx e =
    let loc = e.pexp_loc in
    (* arithmetic operator mutations *)
    (* problem:  duplication between the recursively mutated e' (exp1 + exp2')
                 and the original e (exp + exp')
       solution: let-name locally:
                 let __mutaml_tmp25 = exp1 in
                 let __mutaml_tmp26 = exp2 in
                 if __MUTAML_MUTANT__ = Some 17
                 then __mutaml_tmp25 - __mutaml_tmp26
                 else __mutaml_tmp25 + __mutaml_tmp26  *)
    match e with
    (* A special case mutations: omit 1+ *)
    | [%expr 1 + [%e? exp]] ->
      let exp' = super#expression ctx exp in (* super avoids mut of exp in  1 + exp *)
      let k, tmp_var = self#let_bind ~loc:exp.pexp_loc exp' in
      k (self#mutaml_mutant ctx loc
           { e with pexp_desc = tmp_var.pexp_desc }
           { e with pexp_desc = [%expr 1 + [%e tmp_var]].pexp_desc }
           (string_of_exp exp))
    (* Two special case mutations: omit +1/-1 *)
    | [%expr [%e? exp] + 1]
    | [%expr [%e? exp] - 1] ->
      let op = (match e.pexp_desc with | Pexp_apply (op, _args) -> op | _ -> assert false) in
      let exp' = super#expression ctx exp in (* super avoids mut of exp in  exp +/- 1 *)
      let k, tmp_var = self#let_bind ~loc:exp.pexp_loc exp' in
      k (self#mutaml_mutant ctx loc
           { e with pexp_desc = tmp_var.pexp_desc }
           { e with pexp_desc = [%expr [%e op] [%e tmp_var] 1].pexp_desc }
           (string_of_exp exp))
    (* General binary operator mutations:
        turn "+" into "-", "-" into "+", "*" into "+", "/" into "mod", "mod" into "/" *)
    | [%expr [%e? op] [%e? exp1] [%e? exp2]] ->
      let mut_op = { op with pexp_desc = (match op.pexp_desc with
          | Pexp_ident ({ txt = Lident "+";   loc }) -> Pexp_ident { txt = Lident "-"; loc }
          | Pexp_ident ({ txt = Lident "-";   loc }) -> Pexp_ident { txt = Lident "+"; loc }
          | Pexp_ident ({ txt = Lident "*";   loc }) -> Pexp_ident { txt = Lident "+"; loc }
          | Pexp_ident ({ txt = Lident "/";   loc }) -> Pexp_ident { txt = Lident "mod"; loc }
          | Pexp_ident ({ txt = Lident "mod"; loc }) -> Pexp_ident { txt = Lident "/"; loc }
          | _ ->
            failwith ("mutaml_ppx, mutate_arithmetic: found some other operator case: " ^  (string_of_exp op))
        )} in
         let k1, tmp_var1 = self#let_bind ~loc:exp1.pexp_loc (self#expression ctx exp1) in
         let k2, tmp_var2 = self#let_bind ~loc:exp2.pexp_loc (self#expression ctx exp2) in
         k1 (k2 (self#mutaml_mutant ctx loc
                   { e with pexp_desc = [%expr [%e mut_op] [%e tmp_var1] [%e tmp_var2]].pexp_desc }
                   { e with pexp_desc = [%expr [%e op]     [%e tmp_var1] [%e tmp_var2]].pexp_desc }
                         (string_of_exp [%expr [%e mut_op] [%e exp1]     [%e exp2]])))
    | _ -> failwith "mutaml_ppx, mutate_arithmetic: pattern matching on case is was not applied to"

  method! cases ctx cases =
    let cases = super#cases ctx cases in  (* visit individual cases first *)
    let cases_exc, cases_pure =
      List.partition (fun c -> Match.pat_matches_exception c.pc_lhs) cases in
    let cases_contain_catch_all
      = Match.cases_contain_catch_all cases_pure && List.length cases_pure >= 3 in
    if cases_contain_catch_all || Match.cases_contain_matching_patterns cases_pure
    then
      let instr_cases = self#mutate_pure_cases ctx cases_pure ~cases_contain_catch_all in
      instr_cases @ cases_exc
    else cases

  method mutate_pure_cases ctx cases ~cases_contain_catch_all = match cases with
    | []
    | [_] -> cases
    | case1::(case2::_ as cases') ->
      let cases' = self#mutate_pure_cases ctx cases' ~cases_contain_catch_all in
      if Match.pat_is_catch_all case1.pc_lhs
      then case1::cases' (* neither match for omit-pattern or merge-consecutive *)
      else
      if (not cases_contain_catch_all
      && (not (Match.patterns_agree case1.pc_lhs case2.pc_lhs)
          || Match.pat_is_catch_all case2.pc_lhs))
      || not self#choose_to_mutate
      then case1::cases'
      else
        (* Only allocate mutation if we are going to use it *)
        let loc = { case1.pc_lhs.ppat_loc with (* location of entire case: lhs with guard -> rhs *)
                    loc_end = case1.pc_rhs.pexp_loc.loc_end } in
        let mut_no,mut_id_exp = self#make_mut_number_and_id loc ctx in
        let mut_guard = [%expr __MUTAML_MUTANT__ <> Some [%e mut_id_exp] ] in
        let guard = (match case1.pc_guard with
            | None   -> Some mut_guard
            | Some g -> Some [%expr [%e g] && [%e mut_guard] ]) in
        let case1' = { case1 with pc_guard = guard } in

        if cases_contain_catch_all
        then
          (* drop case from pattern-match when there is a '_'-catch all case and >1 additional cases *)
          (* match f x with             match f x with
              | A -> g y                 | A when __MUTAML_MUTANT__ <> (Some "test:27") -> g y
              | B -> h z        ~~>      | B when __MUTAML_MUTANT__ <> (Some "test:45") -> h z
              | _ -> i q                 | _ -> i q   *)
          let mutation = Mutaml_common.{ number = mut_no; repl = None;
                                         loc = { loc with loc_end = case2.pc_lhs.ppat_loc.loc_start }} in
          (* | pat1 when guard1 -> rhs1  | pat2 when guard2 -> rhs2
               ^---------------------------^
               replaced with (i.e. omitted):
             |                             pat2 when guard2 -> rhs2 *)
          mutations <- mutation::mutations;
          case1'::cases'
        else
          (* merge consecutive cases into an or-pattern  | p1 -> r1 | p2 -> r2  ~~> |p1|p2 -> r2 *)
          (* when no/same variables are bound in each pattern *)
          (* match f x with           match f x with
              | A -> g y               | A when __MUTAML_MUTANT__ <> (Some "test:27") -> g y
              | B -> h z      ~~>      | A | B when __MUTAML_MUTANT__ <> (Some "test:45") -> h z
              | C -> i q               | B | C -> i q *)
          (match cases' with (* recurse and glue or-pattern on case2' *)
           | [] -> failwith "mutaml_ppx, mutate_pure_cases: recursing on a non-empty list yielded back an empty one"
           | case2'::cs' ->
             let or_pat = [%pat? [%p case1.pc_lhs] | [%p case2.pc_lhs]] in
             let repl_str =
               Pprintast.pattern Format.str_formatter or_pat;
               Format.flush_str_formatter () in
             (* | pat1 when guard1 -> rhs1  | pat2        when guard2 -> rhs2
                  ^------------------------------^
                          replaced with:
                | pat1                      | pat2        when guard2 -> rhs2  *)
             let mutation = Mutaml_common.{ number = mut_no;
                                            repl = Some repl_str;  (* diff spans to end of pat2 *)
                                            loc = { loc with loc_end = case2.pc_lhs.ppat_loc.loc_end }} in
             mutations <- mutation::mutations;
             let lhs = { case2'.pc_lhs with ppat_desc = Ppat_or (case1.pc_lhs, case2'.pc_lhs) } in
             let case2'_with_or = { case2' with pc_lhs = lhs } in
             case1'::case2'_with_or::cs')

  method! expression ctx e =
    let loc = e.pexp_loc in
    match e, e.pexp_desc with

    (* asserts represent inline sanity checks/tests - so don't mutate their expressions *)
    (* Furthermore, [assert false] is recognized as a special case and rewritten
       to [raise (Assert_failure ...)] - which is polymorphic:
         https://ocaml.org/manual/expr.html#sss:expr-assertion
       All other forms of 'assert' have [unit] return type.
       This means we can break typing by mutating 'assert false'
       when it is used in a "this-should-never-happen"-case:
         match something with
          | Some x -> i+1
          | None   -> assert false
       which is another reason to avoid mutating that particular form. *)
    | [%expr assert [%e? _]], _-> e

    (* swap bool constructors *)
    | [%expr true],_ when self#choose_to_mutate ->
      let false_exp = { e with pexp_desc = [%expr false].pexp_desc } in
      self#mutaml_mutant ctx loc false_exp e (string_of_exp false_exp)
    | [%expr false],_ when self#choose_to_mutate ->
      let true_exp = { e with pexp_desc = [%expr true].pexp_desc } in
      self#mutaml_mutant ctx loc true_exp e (string_of_exp true_exp)

    | [%expr [%e? _] + [%e? _]],_
    | [%expr [%e? _] - [%e? _]],_
    | [%expr [%e? _] * [%e? _]],_
    | [%expr [%e? _] / [%e? _]],_
    | [%expr [%e? _] mod [%e? _]],_ when self#choose_to_mutate ->
      self#mutate_arithmetic ctx e

    | _, Pexp_constant c when self#choose_to_mutate ->
      let c' = self#mutate_constant ctx c in
      if c = c' then e else
        let e_new = { e with pexp_desc = Pexp_constant c' } in
        self#mutaml_mutant ctx loc e_new e (string_of_exp e_new)

    (* we negate an if's condition rather than swapping its branches:
        * it avoids duplication
        * it works for 1-armed ifs too
                                           if
                                             (let __MUTAML_TMP__ = e0 in
           if e0 then e1 else e2     ~~>      if __MUTAML_MUTANT__ = Some [%e mut_id_exp]
                                              then not __MUTAML_TMP__ else __MUTAML_TMP__)
                                           then e1
                                           else e2       *)
    | _, Pexp_ifthenelse (e0,e1,e2_opt) when self#choose_to_mutate ->
      let e0' = self#expression ctx e0 in
      let e1' = self#expression ctx e1 in
      let e2_opt' = Option.map (self#expression ctx) e2_opt in
      let k, tmp_var = self#let_bind ~loc:e0.pexp_loc e0' in
      let e0'_guarded =
        k (self#mutaml_mutant ctx e0.pexp_loc (*loc*)
             [%expr not [%e tmp_var]]
             [%expr [%e tmp_var]]
             (string_of_exp [%expr not [%e e0]])) in
        { e with pexp_desc = Pexp_ifthenelse (e0'_guarded,e1',e2_opt') }

    (* omit a unit-expression in a sequence:

                             (if __MUTAML_MUTANT__ = Some [%e mut_id_exp]
       e0; e1  ~~>            then ()
                              else e0'); e'  *)
    | _, Pexp_sequence (e0,e1) when self#choose_to_mutate ->
      let e0' = self#expression ctx e0 in
      let e1' = self#expression ctx e1 in
      let e0'' =
        self#mutaml_mutant ctx loc(*e0.pexp_loc*) [%expr ()] e0' (string_of_exp e1) in
      { e0 with pexp_desc = Pexp_sequence (e0'',e1') }

    | _, Pexp_function cases ->
      let cases_pure = self#cases ctx cases in (* all cases are pure in 'function' *)
      let function_ = { e with pexp_desc = Pexp_function cases_pure } in
      if Match.cases_contain_matching_patterns cases_pure
      then
        Exp.attr function_ (* disable pattern-match warning *)
          { attr_name = {txt = "ocaml.warning"; loc};
            attr_payload = PStr [[%stri "-8"]];
            attr_loc = loc }
      else function_

    | _, Pexp_match (me,cases) ->
      let me = super#expression ctx me in
      let cases = self#cases ctx cases in
      let cases_pure = List.filter (fun c -> not (Match.pat_matches_exception c.pc_lhs)) cases in
      let match_ = { e with pexp_desc = Pexp_match (me, cases) } in
      if Match.cases_contain_matching_patterns cases_pure
      then
        Exp.attr match_ (* disable pattern-match warning *)
          { attr_name = {txt = "ocaml.warning"; loc};
            attr_payload = PStr [[%stri "-8"]];
            attr_loc = loc }
      else match_
    | _ ->
      super#expression ctx e


  method transform_impl_file ctx impl_ast =
    let input_name = Base_exp_context.input_name ctx in
    Printf.printf "Running mutaml instrumentation on \"%s\"\n%!" input_name;
    Printf.printf "Randomness seed: %i   %!" !Options.seed;
    Printf.printf "Mutation rate: %i   %!"   !Options.mut_rate;
    Printf.printf "GADTs enabled: %s\n%!"    (Bool.to_string !Options.gadt);

    let instrumented_ast = super#structure ctx impl_ast in
    let mut_count = List.length mutations in
    Printf.printf "Created %i mutation%s of %s\n%!" mut_count (if mut_count=1 then "" else "s") input_name;

    let output_name = write_muts_file input_name mutations in
    let () = append_muts_file_to_log output_name in
    add_preamble instrumented_ast input_name
end
