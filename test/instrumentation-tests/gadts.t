Create dune and dune-project files:

  $ bash ../write_dune_files.sh


An example from Gabriel with GADTs (function-matching).
----------------------------------------------------------------------------

  $ cat > test.ml <<'EOF'
  > type _ t =
  >   | Int : int t
  >   | Bool : bool t
  > 
  > let f (type a) : a t -> a = function
  >   | Int -> 0
  >   | Bool -> true
  > 
  > let () = f Int |> Printf.printf "%i\n"
  > EOF


Check that the example typechecks
  $ ocamlc -stop-after typing test.ml
  $ export MUTAML_SEED=896745231
  $ export MUTAML_MUT_RATE=100
  $ export MUTAML_GADT=true
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 2 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type _ t =
    | Int: int t 
    | Bool: bool t 
  let f (type a) =
    (function
     | Int -> if __MUTAML_MUTANT__ = (Some "test:0") then 1 else 0
     | Bool -> if __MUTAML_MUTANT__ = (Some "test:1") then false else true : 
    a t -> a)
  let () = (f Int) |> (Printf.printf "%i\n")

This shouldn't fail. It should just fail to mutate the patterns.




Parse tree of GADT example

  $ ocamlc -dparsetree test.ml 2>&1 | sed -e 's/ ghost//'
  [
    structure_item (test.ml[1,0+0]..[3,27+17])
      Pstr_type Rec
      [
        type_declaration "t" (test.ml[1,0+7]..[1,0+8]) (test.ml[1,0+0]..[3,27+17])
          ptype_params =
            [
              core_type (test.ml[1,0+5]..[1,0+6])
                Ptyp_any
            ]
          ptype_cstrs =
            []
          ptype_kind =
            Ptype_variant
              [
                (test.ml[2,11+2]..[2,11+15])
                  "Int" (test.ml[2,11+4]..[2,11+7])
                  []
                  Some
                    core_type (test.ml[2,11+10]..[2,11+15])
                      Ptyp_constr "t" (test.ml[2,11+14]..[2,11+15])
                      [
                        core_type (test.ml[2,11+10]..[2,11+13])
                          Ptyp_constr "int" (test.ml[2,11+10]..[2,11+13])
                          []
                      ]
                (test.ml[3,27+2]..[3,27+17])
                  "Bool" (test.ml[3,27+4]..[3,27+8])
                  []
                  Some
                    core_type (test.ml[3,27+11]..[3,27+17])
                      Ptyp_constr "t" (test.ml[3,27+16]..[3,27+17])
                      [
                        core_type (test.ml[3,27+11]..[3,27+15])
                          Ptyp_constr "bool" (test.ml[3,27+11]..[3,27+15])
                          []
                      ]
              ]
          ptype_private = Public
          ptype_manifest =
            None
      ]
    structure_item (test.ml[5,46+0]..[7,96+16])
      Pstr_value Nonrec
      [
        <def>
          pattern (test.ml[5,46+4]..[5,46+5])
            Ppat_var "f" (test.ml[5,46+4]..[5,46+5])
          expression (test.ml[5,46+6]..[7,96+16])
            Pexp_newtype "a"
            expression (test.ml[5,46+15]..[7,96+16])
              Pexp_constraint
              expression (test.ml[5,46+28]..[7,96+16])
                Pexp_function
                [
                  <case>
                    pattern (test.ml[6,83+4]..[6,83+7])
                      Ppat_construct "Int" (test.ml[6,83+4]..[6,83+7])
                      None
                    expression (test.ml[6,83+11]..[6,83+12])
                      Pexp_constant PConst_int (0,None)
                  <case>
                    pattern (test.ml[7,96+4]..[7,96+8])
                      Ppat_construct "Bool" (test.ml[7,96+4]..[7,96+8])
                      None
                    expression (test.ml[7,96+12]..[7,96+16])
                      Pexp_construct "true" (test.ml[7,96+12]..[7,96+16])
                      None
                ]
              core_type (test.ml[5,46+17]..[5,46+25])
                Ptyp_arrow
                Nolabel
                core_type (test.ml[5,46+17]..[5,46+20])
                  Ptyp_constr "t" (test.ml[5,46+19]..[5,46+20])
                  [
                    core_type (test.ml[5,46+17]..[5,46+18])
                      Ptyp_constr "a" (test.ml[5,46+17]..[5,46+18])
                      []
                  ]
                core_type (test.ml[5,46+24]..[5,46+25])
                  Ptyp_constr "a" (test.ml[5,46+24]..[5,46+25])
                  []
      ]
    structure_item (test.ml[9,114+0]..[9,114+38])
      Pstr_value Nonrec
      [
        <def>
          pattern (test.ml[9,114+4]..[9,114+6])
            Ppat_construct "()" (test.ml[9,114+4]..[9,114+6])
            None
          expression (test.ml[9,114+9]..[9,114+38])
            Pexp_apply
            expression (test.ml[9,114+15]..[9,114+17])
              Pexp_ident "|>" (test.ml[9,114+15]..[9,114+17])
            [
              <arg>
              Nolabel
                expression (test.ml[9,114+9]..[9,114+14])
                  Pexp_apply
                  expression (test.ml[9,114+9]..[9,114+10])
                    Pexp_ident "f" (test.ml[9,114+9]..[9,114+10])
                  [
                    <arg>
                    Nolabel
                      expression (test.ml[9,114+11]..[9,114+14])
                        Pexp_construct "Int" (test.ml[9,114+11]..[9,114+14])
                        None
                  ]
              <arg>
              Nolabel
                expression (test.ml[9,114+18]..[9,114+38])
                  Pexp_apply
                  expression (test.ml[9,114+18]..[9,114+31])
                    Pexp_ident "Printf.printf" (test.ml[9,114+18]..[9,114+31])
                  [
                    <arg>
                    Nolabel
                      expression (test.ml[9,114+32]..[9,114+38])
                        Pexp_constant PConst_string("%i\n",(test.ml[9,114+33]..[9,114+37]),None)
                  ]
            ]
      ]
  ]
  




Same example from Gabriel with GADTs ('match'-matching)
--------------------------------------------------------------------------------

  $ cat > test.ml <<'EOF'
  > type _ t =
  >   | Int : int t
  >   | Bool : bool t
  > 
  > let f (type a) : a t -> a = fun x -> match x with
  >   | Int -> 0
  >   | Bool -> true
  > 
  > let () = f Int |> Printf.printf "%i\n"
  > EOF

Check that the example typechecks
  $ ocamlc -stop-after typing test.ml
  $ export MUTAML_SEED=896745231
  $ export MUTAML_GADT=true
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 2 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type _ t =
    | Int: int t 
    | Bool: bool t 
  let f (type a) =
    (fun x ->
       match x with
       | Int -> if __MUTAML_MUTANT__ = (Some "test:0") then 1 else 0
       | Bool -> if __MUTAML_MUTANT__ = (Some "test:1") then false else true : 
    a t -> a)
  let () = (f Int) |> (Printf.printf "%i\n")

This shouldn't fail. It should just fail to mutate the patterns.




GADT example from the manual
--------------------------------------------------------------------------------

  $ cat > test.ml <<'EOF'
  > type _ t =
  >   | Int : int t
  >   | Bool : bool t
  > 
  > let deep : (char t * int) option -> char = function
  >  | None -> 'c'
  >  | _ -> .
  > EOF

Check that the example typechecks
  $ ocamlc -stop-after typing test.ml
  $ export MUTAML_SEED=896745231
  $ export MUTAML_GADT=true
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type _ t =
    | Int: int t 
    | Bool: bool t 
  let deep : (char t * int) option -> char = function | None -> 'c' | _ -> .

This shouldn't fail. It should just fail to mutate the patterns.



Parse tree of GADT example with refutation case

  $ ocamlc -dparsetree test.ml 2>&1 | sed -e 's/ ghost//'
  [
    structure_item (test.ml[1,0+0]..[3,27+17])
      Pstr_type Rec
      [
        type_declaration "t" (test.ml[1,0+7]..[1,0+8]) (test.ml[1,0+0]..[3,27+17])
          ptype_params =
            [
              core_type (test.ml[1,0+5]..[1,0+6])
                Ptyp_any
            ]
          ptype_cstrs =
            []
          ptype_kind =
            Ptype_variant
              [
                (test.ml[2,11+2]..[2,11+15])
                  "Int" (test.ml[2,11+4]..[2,11+7])
                  []
                  Some
                    core_type (test.ml[2,11+10]..[2,11+15])
                      Ptyp_constr "t" (test.ml[2,11+14]..[2,11+15])
                      [
                        core_type (test.ml[2,11+10]..[2,11+13])
                          Ptyp_constr "int" (test.ml[2,11+10]..[2,11+13])
                          []
                      ]
                (test.ml[3,27+2]..[3,27+17])
                  "Bool" (test.ml[3,27+4]..[3,27+8])
                  []
                  Some
                    core_type (test.ml[3,27+11]..[3,27+17])
                      Ptyp_constr "t" (test.ml[3,27+16]..[3,27+17])
                      [
                        core_type (test.ml[3,27+11]..[3,27+15])
                          Ptyp_constr "bool" (test.ml[3,27+11]..[3,27+15])
                          []
                      ]
              ]
          ptype_private = Public
          ptype_manifest =
            None
      ]
    structure_item (test.ml[5,46+0]..[7,113+9])
      Pstr_value Nonrec
      [
        <def>
          pattern (test.ml[5,46+4]..[5,46+40])
            Ppat_constraint
            pattern (test.ml[5,46+4]..[5,46+8])
              Ppat_var "deep" (test.ml[5,46+4]..[5,46+8])
            core_type (test.ml[5,46+11]..[5,46+40])
              Ptyp_poly
              core_type (test.ml[5,46+11]..[5,46+40])
                Ptyp_arrow
                Nolabel
                core_type (test.ml[5,46+11]..[5,46+32])
                  Ptyp_constr "option" (test.ml[5,46+26]..[5,46+32])
                  [
                    core_type (test.ml[5,46+12]..[5,46+24])
                      Ptyp_tuple
                      [
                        core_type (test.ml[5,46+12]..[5,46+18])
                          Ptyp_constr "t" (test.ml[5,46+17]..[5,46+18])
                          [
                            core_type (test.ml[5,46+12]..[5,46+16])
                              Ptyp_constr "char" (test.ml[5,46+12]..[5,46+16])
                              []
                          ]
                        core_type (test.ml[5,46+21]..[5,46+24])
                          Ptyp_constr "int" (test.ml[5,46+21]..[5,46+24])
                          []
                      ]
                  ]
                core_type (test.ml[5,46+36]..[5,46+40])
                  Ptyp_constr "char" (test.ml[5,46+36]..[5,46+40])
                  []
          expression (test.ml[5,46+4]..[7,113+9])
            Pexp_constraint
            expression (test.ml[5,46+43]..[7,113+9])
              Pexp_function
              [
                <case>
                  pattern (test.ml[6,98+3]..[6,98+7])
                    Ppat_construct "None" (test.ml[6,98+3]..[6,98+7])
                    None
                  expression (test.ml[6,98+11]..[6,98+14])
                    Pexp_constant PConst_char 63
                <case>
                  pattern (test.ml[7,113+3]..[7,113+4])
                    Ppat_any
                  expression (test.ml[7,113+8]..[7,113+9])
                    Pexp_unreachable            ]
            core_type (test.ml[5,46+11]..[5,46+40])
              Ptyp_arrow
              Nolabel
              core_type (test.ml[5,46+11]..[5,46+32])
                Ptyp_constr "option" (test.ml[5,46+26]..[5,46+32])
                [
                  core_type (test.ml[5,46+12]..[5,46+24])
                    Ptyp_tuple
                    [
                      core_type (test.ml[5,46+12]..[5,46+18])
                        Ptyp_constr "t" (test.ml[5,46+17]..[5,46+18])
                        [
                          core_type (test.ml[5,46+12]..[5,46+16])
                            Ptyp_constr "char" (test.ml[5,46+12]..[5,46+16])
                            []
                        ]
                      core_type (test.ml[5,46+21]..[5,46+24])
                        Ptyp_constr "int" (test.ml[5,46+21]..[5,46+24])
                        []
                    ]
                ]
              core_type (test.ml[5,46+36]..[5,46+40])
                Ptyp_constr "char" (test.ml[5,46+36]..[5,46+40])
                []
      ]
  ]
  






GADT example from manual w.match + an impossible case
--------------------------------------------------------------------------------

  $ cat > test.ml <<'EOF'
  > type _ t =
  >   | Int : int t
  >   | Bool : bool t
  > 
  > let deep_match : (char t * int) option -> char = fun x -> match x with
  >  | None -> 'c'
  >  | Some (_,0) -> .
  >  | _ -> .
  > EOF

Check that the example typechecks
  $ ocamlc -stop-after typing test.ml
  $ export MUTAML_SEED=896745231
  $ export MUTAML_GADT=true
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type _ t =
    | Int: int t 
    | Bool: bool t 
  let deep_match : (char t * int) option -> char =
    fun x -> match x with | None -> 'c' | Some (_, 0) -> . | _ -> .

This shouldn't fail. It should just fail to mutate the patterns.





GADT example from manual w.match
--------------------------------------------------------------------------------

  $ cat > test.ml <<'EOF'
  > type _ t =
  >   | Int : int t
  >   | Bool : bool t
  > 
  > let deep_match_refut : (char t * int) option -> char = fun x -> match x with
  >  | None -> 'c'
  >  (*| Some (_,0) -> .*)  (*impossible, type-wise*)
  >  | Some (_,_i) -> .  (*impossible, type-wise*)
  > EOF

Check that the example typechecks
  $ ocamlc -stop-after typing test.ml
  $ export MUTAML_SEED=896745231
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type _ t =
    | Int: int t 
    | Bool: bool t 
  let deep_match_refut : (char t * int) option -> char =
    fun x -> match x with | None -> 'c' | Some (_, _i) -> .


This shouldn't fail. It should just fail to mutate the patterns.





More GADT examples
--------------------------------------------------------------------------------

Pattern matching on GADT constructors in arrays:

  $ cat > test.ml <<'EOF'
  > type _ t =
  >   | Int : int t
  >   | Bool : bool t
  > 
  > let f (type a) : a t array -> a = function
  >  | [| Int ; Int |] -> 0
  >  | [| Bool |] -> true
  >  | _ -> failwith "ouch"
  > EOF

Check that the example typechecks
  $ ocamlc -stop-after typing test.ml
  $ export MUTAML_SEED=896745231
  $ export MUTAML_GADT=true
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 4 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type _ t =
    | Int: int t 
    | Bool: bool t 
  let f (type a) =
    (function
     | [|Int;Int|] when __MUTAML_MUTANT__ <> (Some "test:3") ->
         if __MUTAML_MUTANT__ = (Some "test:0") then 1 else 0
     | [|Bool|] when __MUTAML_MUTANT__ <> (Some "test:2") ->
         if __MUTAML_MUTANT__ = (Some "test:1") then false else true
     | _ -> failwith "ouch" : a t array -> a)



Pattern matching on GADT constructors in arrays:

  $ cat > test.ml <<'EOF'
  > type _ t =
  >   | Int : int t
  >   | Bool : bool t
  >   | Char : char t
  > 
  > let f (type a) : a t array -> a = function
  >  | [| Int  |] -> 0
  >  | [| Bool |] -> true
  >  | [| Char |] -> 'c'
  >  | _ when true (*2*2=2+2*) -> failwith "empty"
  >  | _ when false -> failwith "dead"
  > EOF

Check that the example typechecks
  $ ocamlc -stop-after typing test.ml
  File "test.ml", lines 6-11, characters 34-34:
   6 | ..................................function
   7 |  | [| Int  |] -> 0
   8 |  | [| Bool |] -> true
   9 |  | [| Char |] -> 'c'
  10 |  | _ when true (*2*2=2+2*) -> failwith "empty"
  11 |  | _ when false -> failwith "dead"
  Warning 8 [partial-match]: this pattern-matching is not exhaustive.
  Here is an example of a case that is not matched:
  [|  |]
  (However, some guarded clause may match this value.)
  $ export MUTAML_SEED=896745231
  $ export MUTAML_GADT=true
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml 2>&1 > output.txt
  $ head -n 4 output.txt && echo "ERROR MESSAGE" && tail -n 25 output.txt
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 4 mutations of test.ml
  Writing mutation info to test.muts
  ERROR MESSAGE
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type _ t =
    | Int: int t 
    | Bool: bool t 
    | Char: char t 
  let f (type a) =
    (function
     | [|Int|] -> if __MUTAML_MUTANT__ = (Some "test:0") then 1 else 0
     | [|Bool|] -> if __MUTAML_MUTANT__ = (Some "test:1") then false else true
     | [|Char|] -> 'c'
     | _ when if __MUTAML_MUTANT__ = (Some "test:2") then false else true ->
         failwith "empty"
     | _ when if __MUTAML_MUTANT__ = (Some "test:3") then true else false ->
         failwith "dead" : a t array -> a)
  File "test.ml", lines 6-11, characters 34-34:
   6 | ..................................function
   7 |  | [| Int  |] -> 0
   8 |  | [| Bool |] -> true
   9 |  | [| Char |] -> 'c'
  10 |  | _ when true (*2*2=2+2*) -> failwith "empty"
  11 |  | _ when false -> failwith "dead"
  Error (warning 8 [partial-match]): this pattern-matching is not exhaustive.
  Here is an example of a case that is not matched:
  [|  |]
  (However, some guarded clause may match this value.)




Pattern matching on GADT constructors in arrays w.variables:

  $ cat > test.ml <<'EOF'
  > type _ t =
  >   | Int : int t
  >   | Bool : bool t
  > let f (type a) : a t array -> a = function
  >  | [| _x ; Int |] -> 2
  >  | [| Bool ; _x |] -> true
  >  | _ -> failwith "eww";;
  > EOF

Check that the example typechecks
  $ ocamlc -stop-after typing test.ml
  $ export MUTAML_SEED=896745231
  $ export MUTAML_GADT=true
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 4 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type _ t =
    | Int: int t 
    | Bool: bool t 
  let f (type a) =
    (function
     | [|_x;Int|] when __MUTAML_MUTANT__ <> (Some "test:3") ->
         if __MUTAML_MUTANT__ = (Some "test:0") then 3 else 2
     | [|Bool;_x|] when __MUTAML_MUTANT__ <> (Some "test:2") ->
         if __MUTAML_MUTANT__ = (Some "test:1") then false else true
     | _ -> failwith "eww" : a t array -> a)




Pattern matching on GADT constructors in tuples, polymorphically:

  $ cat > test.ml <<'EOF'
  > type _ t =
  >   | Int : int t
  >   | Bool : bool t
  > 
  > let _f (type a) (type b) : (a t * b t) -> int = function | (Int,_) -> 0  | (_,Bool) -> 1 | _ -> 2
  > 
  > let _f (type a) (type b) : (a t * b t) -> int = function | (Int,Int) -> 0  | (Bool,Bool) -> 1 | _ -> 2
  > EOF

Check that the example typechecks
  $ ocamlc -stop-after typing test.ml
  $ export MUTAML_SEED=896745231
  $ export MUTAML_GADT=true
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 10 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type _ t =
    | Int: int t 
    | Bool: bool t 
  let _f (type a) (type b) =
    (function
     | (Int, _) when __MUTAML_MUTANT__ <> (Some "test:4") ->
         if __MUTAML_MUTANT__ = (Some "test:0") then 1 else 0
     | (_, Bool) when __MUTAML_MUTANT__ <> (Some "test:3") ->
         if __MUTAML_MUTANT__ = (Some "test:1") then 0 else 1
     | _ -> if __MUTAML_MUTANT__ = (Some "test:2") then 3 else 2 : (a t * b t)
                                                                     -> 
                                                                     int)
  let _f (type a) (type b) =
    (function
     | (Int, Int) when __MUTAML_MUTANT__ <> (Some "test:9") ->
         if __MUTAML_MUTANT__ = (Some "test:5") then 1 else 0
     | (Bool, Bool) when __MUTAML_MUTANT__ <> (Some "test:8") ->
         if __MUTAML_MUTANT__ = (Some "test:6") then 0 else 1
     | _ -> if __MUTAML_MUTANT__ = (Some "test:7") then 3 else 2 : (a t * b t)
                                                                     -> 
                                                                     int)



Pattern matching on GADT constructors in tuples, concretely:

  $ cat > test.ml <<'EOF'
  > type _ t =
  >   | Int : int t
  >   | Bool : bool t
  > 
  > let _f : (int t * bool t) -> int = function | (Int,_) -> 0  | (_,Bool) -> . | _ -> .
  > 
  > let _f : (int t * bool t) -> int = function | (Int,_) -> 0  | (_,Bool) -> .
  > 
  > let _f : (int t * bool t) -> int = function | (Int,_) -> 0
  > EOF

Check that the example typechecks
  $ ocamlc -stop-after typing test.ml
  $ export MUTAML_SEED=896745231
  $ export MUTAML_GADT=true
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 3 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type _ t =
    | Int: int t 
    | Bool: bool t 
  let _f : (int t * bool t) -> int =
    function
    | (Int, _) -> if __MUTAML_MUTANT__ = (Some "test:0") then 1 else 0
    | (_, Bool) -> .
    | _ -> .
  let _f : (int t * bool t) -> int =
    function
    | (Int, _) -> if __MUTAML_MUTANT__ = (Some "test:1") then 1 else 0
    | (_, Bool) -> .
  let _f : (int t * bool t) -> int =
    function | (Int, _) -> if __MUTAML_MUTANT__ = (Some "test:2") then 1 else 0




Another example from the manual:

  $ cat > test.ml <<'EOF'
  > type _ typ =
  >   | Int : int typ
  >   | String : string typ
  >   | Pair : 'a typ * 'b typ -> ('a * 'b) typ
  > 
  > let rec to_string: type t. t typ -> t -> string =
  >   fun t x ->
  >   match t with
  >   | Int -> Int.to_string x
  >   | String -> Printf.sprintf "%S" x
  >   | Pair(t1,t2) ->
  >       let (x1, x2) = x in
  >       Printf.sprintf "(%s,%s)" (to_string t1 x1) (to_string t2 x2)
  > EOF

Check that the example typechecks
  $ ocamlc -stop-after typing test.ml
  $ export MUTAML_SEED=896745231
  $ export MUTAML_GADT=true
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type _ typ =
    | Int: int typ 
    | String: string typ 
    | Pair: 'a typ * 'b typ -> ('a * 'b) typ 
  let rec to_string : type t. t typ -> t -> string =
    fun t ->
      fun x ->
        match t with
        | Int -> Int.to_string x
        | String -> Printf.sprintf "%S" x
        | Pair (t1, t2) ->
            let (x1, x2) = x in
            Printf.sprintf "(%s,%s)" (to_string t1 x1) (to_string t2 x2)
