Create dune and dune-project files:
  $ bash write_dune_files.sh

Make an .ml-file:
  $ cat > test.ml <<'EOF'
  > let () = match !Sys.interactive with
  >   | false -> print_endline "Running in batch mode"
  >   | true  -> print_endline "Running interactively"
  > EOF


This gets parsed to the following syntax tree:

  $ ocamlc -dparsetree test.ml
  [
    structure_item (test.ml[1,0+0]..[3,88+50])
      Pstr_value Nonrec
      [
        <def>
          pattern (test.ml[1,0+4]..[1,0+6])
            Ppat_construct "()" (test.ml[1,0+4]..[1,0+6])
            None
          expression (test.ml[1,0+9]..[3,88+50])
            Pexp_match
            expression (test.ml[1,0+15]..[1,0+31])
              Pexp_apply
              expression (test.ml[1,0+15]..[1,0+16])
                Pexp_ident "!" (test.ml[1,0+15]..[1,0+16])
              [
                <arg>
                Nolabel
                  expression (test.ml[1,0+16]..[1,0+31])
                    Pexp_ident "Sys.interactive" (test.ml[1,0+16]..[1,0+31])
              ]
            [
              <case>
                pattern (test.ml[2,37+4]..[2,37+9])
                  Ppat_construct "false" (test.ml[2,37+4]..[2,37+9])
                  None
                expression (test.ml[2,37+13]..[2,37+50])
                  Pexp_apply
                  expression (test.ml[2,37+13]..[2,37+26])
                    Pexp_ident "print_endline" (test.ml[2,37+13]..[2,37+26])
                  [
                    <arg>
                    Nolabel
                      expression (test.ml[2,37+27]..[2,37+50])
                        Pexp_constant PConst_string("Running in batch mode",(test.ml[2,37+28]..[2,37+49]),None)
                  ]
              <case>
                pattern (test.ml[3,88+4]..[3,88+8])
                  Ppat_construct "true" (test.ml[3,88+4]..[3,88+8])
                  None
                expression (test.ml[3,88+13]..[3,88+50])
                  Pexp_apply
                  expression (test.ml[3,88+13]..[3,88+26])
                    Pexp_ident "print_endline" (test.ml[3,88+13]..[3,88+26])
                  [
                    <arg>
                    Nolabel
                      expression (test.ml[3,88+27]..[3,88+50])
                        Pexp_constant PConst_string("Running interactively",(test.ml[3,88+28]..[3,88+49]),None)
                  ]
            ]
      ]
  ]
  



Let's first compile and run the example
---------------------------------------

Set seed and (full) mutation rate as environment variables, for repeatability
  $ export MUTAML_SEED=896745231
  $ export MUTAML_MUT_RATE=100

  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let () =
    match !Sys.interactive with
    | false -> print_endline "Running in batch mode"
    | true -> print_endline "Running interactively"

  $ dune exec --no-build ./test.bc
  Running in batch mode


Same example but with GADT-unsafe mutations enabled:
----------------------------------------------------

  $ dune clean

  $ export MUTAML_GADT=false

  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: false
  Created 1 mutation of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let () =
    ((match !Sys.interactive with
      | false when __MUTAML_MUTANT__ <> (Some "test:0") ->
          print_endline "Running in batch mode"
      | false | true -> print_endline "Running interactively")
    [@ocaml.warning "-8"])


  $ dune exec --no-build ./test.bc
  Running in batch mode

  $ MUTAML_MUTANT="test:0" dune exec --no-build ./test.bc
  Running interactively

  $ unset MUTAML_GADT



Another example:
--------------------------------------------------------------------------------

  $ cat > test.ml <<'EOF'
  > type t = A | B | C
  > 
  > let f x = match x with
  > | A -> "A"
  > | B -> "B"
  > | C -> "C"
  > 
  > let () = f A |> print_endline
  > let () = f B |> print_endline
  > let () = f C |> print_endline
  > EOF

  $ export MUTAML_SEED=896745231
  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type t =
    | A 
    | B 
    | C 
  let f x = match x with | A -> "A" | B -> "B" | C -> "C"
  let () = (f A) |> print_endline
  let () = (f B) |> print_endline
  let () = (f C) |> print_endline


  $ dune exec --no-build ./test.bc
  A
  B
  C


Same example but with GADT-unsafe mutations enabled:
----------------------------------------------------

  $ dune clean

  $ export MUTAML_GADT=false

  $ export MUTAML_SEED=896745231

  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: false
  Created 2 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type t =
    | A 
    | B 
    | C 
  let f x =
    ((match x with
      | A when __MUTAML_MUTANT__ <> (Some "test:1") -> "A"
      | A | B when __MUTAML_MUTANT__ <> (Some "test:0") -> "B"
      | B | C -> "C")
    [@ocaml.warning "-8"])
  let () = (f A) |> print_endline
  let () = (f B) |> print_endline
  let () = (f C) |> print_endline


  $ _build/default/test.bc
  A
  B
  C

  $ MUTAML_MUTANT="test:0" _build/default/test.bc
  A
  C
  C

  $ MUTAML_MUTANT="test:1" _build/default/test.bc
  B
  B
  C


  $ mutaml-runner _build/default/test.bc
  read mut file test.muts
  Testing mutant test:0 ... passed
  Testing mutant test:1 ... passed
  Writing report data to mutaml-report.json


  $ mutaml-report
  Attempting to read from mutaml-report.json...
  
  Mutaml report summary:
  ----------------------
  
   target                          #mutations      #failed      #timeouts      #passed 
   -------------------------------------------------------------------------------------
   test.ml                                2       0.0%    0     0.0%    0   100.0%    2
   =====================================================================================
  
  Mutation programs passing the test suite:
  -----------------------------------------
  
  Mutation "test.ml-mutant0" passed (see "_mutations/test.ml-mutant0.output"):
  
  --- test.ml
  +++ test.ml-mutant0
  @@ -2,8 +2,7 @@
   
   let f x = match x with
   | A -> "A"
  -| B -> "B"
  -| C -> "C"
  +| B | C -> "C"
   
   let () = f A |> print_endline
   let () = f B |> print_endline
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant1" passed (see "_mutations/test.ml-mutant1.output"):
  
  --- test.ml
  +++ test.ml-mutant1
  @@ -1,8 +1,7 @@
   type t = A | B | C
   
   let f x = match x with
  -| A -> "A"
  -| B -> "B"
  +| A | B -> "B"
   | C -> "C"
   
   let () = f A |> print_endline
  
  ---------------------------------------------------------------------------
  

  $ unset MUTAML_GADT




Another test program:
--------------------------------------------------------------------------------

Make an .ml-file:
  $ cat > test.ml <<'EOF'
  > let rec count_zeroes xs = match xs with
  >   | [] -> 0
  >   | 0::xs -> 1 + (count_zeroes xs)
  >   | _::xs -> count_zeroes xs
  > let () = count_zeroes [] |> Printf.printf "%i\n"
  > let () = count_zeroes [1;0] |> Printf.printf "%i\n"
  > let () = count_zeroes [0;1;0] |> Printf.printf "%i\n"
  > let () = count_zeroes [1;0;0;1;0] |> Printf.printf "%i\n"
  > EOF

--------------------------------------------------------------------------------

This example does not trigger the "omit" case mutation
as the last pattern matching constructor '::' is not a catch all.
Instead we trigger the collapse-consecutive-patterns mutation:

  $ export MUTAML_SEED=896745231

  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 13 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let rec count_zeroes xs =
    ((match xs with
      | [] -> if __MUTAML_MUTANT__ = (Some "test:0") then 1 else 0
      | 0::xs when __MUTAML_MUTANT__ <> (Some "test:2") ->
          let __MUTAML_TMP0__ = count_zeroes xs in
          if __MUTAML_MUTANT__ = (Some "test:1")
          then __MUTAML_TMP0__
          else 1 + __MUTAML_TMP0__
      | 0::xs | _::xs -> count_zeroes xs)
    [@ocaml.warning "-8"])
  let () = (count_zeroes []) |> (Printf.printf "%i\n")
  let () =
    (count_zeroes
       [if __MUTAML_MUTANT__ = (Some "test:3") then 0 else 1;
       if __MUTAML_MUTANT__ = (Some "test:4") then 1 else 0])
      |> (Printf.printf "%i\n")
  let () =
    (count_zeroes
       [if __MUTAML_MUTANT__ = (Some "test:5") then 1 else 0;
       if __MUTAML_MUTANT__ = (Some "test:6") then 0 else 1;
       if __MUTAML_MUTANT__ = (Some "test:7") then 1 else 0])
      |> (Printf.printf "%i\n")
  let () =
    (count_zeroes
       [if __MUTAML_MUTANT__ = (Some "test:8") then 0 else 1;
       if __MUTAML_MUTANT__ = (Some "test:9") then 1 else 0;
       if __MUTAML_MUTANT__ = (Some "test:10") then 1 else 0;
       if __MUTAML_MUTANT__ = (Some "test:11") then 0 else 1;
       if __MUTAML_MUTANT__ = (Some "test:12") then 1 else 0])
      |> (Printf.printf "%i\n")

  $ _build/default/test.bc
  0
  1
  2
  3

  $ MUTAML_MUTANT="test:2" _build/default/test.bc
  0
  0
  0
  0


  $ mutaml-runner _build/default/test.bc
  read mut file test.muts
  Testing mutant test:0 ... passed
  Testing mutant test:1 ... passed
  Testing mutant test:2 ... passed
  Testing mutant test:3 ... passed
  Testing mutant test:4 ... passed
  Testing mutant test:5 ... passed
  Testing mutant test:6 ... passed
  Testing mutant test:7 ... passed
  Testing mutant test:8 ... passed
  Testing mutant test:9 ... passed
  Testing mutant test:10 ... passed
  Testing mutant test:11 ... passed
  Testing mutant test:12 ... passed
  Writing report data to mutaml-report.json


  $ mutaml-report
  Attempting to read from mutaml-report.json...
  
  Mutaml report summary:
  ----------------------
  
   target                          #mutations      #failed      #timeouts      #passed 
   -------------------------------------------------------------------------------------
   test.ml                               13       0.0%    0     0.0%    0   100.0%   13
   =====================================================================================
  
  Mutation programs passing the test suite:
  -----------------------------------------
  
  Mutation "test.ml-mutant0" passed (see "_mutations/test.ml-mutant0.output"):
  
  --- test.ml
  +++ test.ml-mutant0
  @@ -1,5 +1,5 @@
   let rec count_zeroes xs = match xs with
  -  | [] -> 0
  +  | [] -> 1
     | 0::xs -> 1 + (count_zeroes xs)
     | _::xs -> count_zeroes xs
   let () = count_zeroes [] |> Printf.printf "%i\n"
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant1" passed (see "_mutations/test.ml-mutant1.output"):
  
  --- test.ml
  +++ test.ml-mutant1
  @@ -1,6 +1,6 @@
   let rec count_zeroes xs = match xs with
     | [] -> 0
  -  | 0::xs -> 1 + (count_zeroes xs)
  +  | 0::xs -> count_zeroes xs
     | _::xs -> count_zeroes xs
   let () = count_zeroes [] |> Printf.printf "%i\n"
   let () = count_zeroes [1;0] |> Printf.printf "%i\n"
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant2" passed (see "_mutations/test.ml-mutant2.output"):
  
  --- test.ml
  +++ test.ml-mutant2
  @@ -1,7 +1,6 @@
   let rec count_zeroes xs = match xs with
     | [] -> 0
  -  | 0::xs -> 1 + (count_zeroes xs)
  -  | _::xs -> count_zeroes xs
  +  | 0::xs | _::xs -> count_zeroes xs
   let () = count_zeroes [] |> Printf.printf "%i\n"
   let () = count_zeroes [1;0] |> Printf.printf "%i\n"
   let () = count_zeroes [0;1;0] |> Printf.printf "%i\n"
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant3" passed (see "_mutations/test.ml-mutant3.output"):
  
  --- test.ml
  +++ test.ml-mutant3
  @@ -3,6 +3,6 @@
     | 0::xs -> 1 + (count_zeroes xs)
     | _::xs -> count_zeroes xs
   let () = count_zeroes [] |> Printf.printf "%i\n"
  -let () = count_zeroes [1;0] |> Printf.printf "%i\n"
  +let () = count_zeroes [0;0] |> Printf.printf "%i\n"
   let () = count_zeroes [0;1;0] |> Printf.printf "%i\n"
   let () = count_zeroes [1;0;0;1;0] |> Printf.printf "%i\n"
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant4" passed (see "_mutations/test.ml-mutant4.output"):
  
  --- test.ml
  +++ test.ml-mutant4
  @@ -3,6 +3,6 @@
     | 0::xs -> 1 + (count_zeroes xs)
     | _::xs -> count_zeroes xs
   let () = count_zeroes [] |> Printf.printf "%i\n"
  -let () = count_zeroes [1;0] |> Printf.printf "%i\n"
  +let () = count_zeroes [1;1] |> Printf.printf "%i\n"
   let () = count_zeroes [0;1;0] |> Printf.printf "%i\n"
   let () = count_zeroes [1;0;0;1;0] |> Printf.printf "%i\n"
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant5" passed (see "_mutations/test.ml-mutant5.output"):
  
  --- test.ml
  +++ test.ml-mutant5
  @@ -4,5 +4,5 @@
     | _::xs -> count_zeroes xs
   let () = count_zeroes [] |> Printf.printf "%i\n"
   let () = count_zeroes [1;0] |> Printf.printf "%i\n"
  -let () = count_zeroes [0;1;0] |> Printf.printf "%i\n"
  +let () = count_zeroes [1;1;0] |> Printf.printf "%i\n"
   let () = count_zeroes [1;0;0;1;0] |> Printf.printf "%i\n"
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant6" passed (see "_mutations/test.ml-mutant6.output"):
  
  --- test.ml
  +++ test.ml-mutant6
  @@ -4,5 +4,5 @@
     | _::xs -> count_zeroes xs
   let () = count_zeroes [] |> Printf.printf "%i\n"
   let () = count_zeroes [1;0] |> Printf.printf "%i\n"
  -let () = count_zeroes [0;1;0] |> Printf.printf "%i\n"
  +let () = count_zeroes [0;0;0] |> Printf.printf "%i\n"
   let () = count_zeroes [1;0;0;1;0] |> Printf.printf "%i\n"
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant7" passed (see "_mutations/test.ml-mutant7.output"):
  
  --- test.ml
  +++ test.ml-mutant7
  @@ -4,5 +4,5 @@
     | _::xs -> count_zeroes xs
   let () = count_zeroes [] |> Printf.printf "%i\n"
   let () = count_zeroes [1;0] |> Printf.printf "%i\n"
  -let () = count_zeroes [0;1;0] |> Printf.printf "%i\n"
  +let () = count_zeroes [0;1;1] |> Printf.printf "%i\n"
   let () = count_zeroes [1;0;0;1;0] |> Printf.printf "%i\n"
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant8" passed (see "_mutations/test.ml-mutant8.output"):
  
  --- test.ml
  +++ test.ml-mutant8
  @@ -5,4 +5,4 @@
   let () = count_zeroes [] |> Printf.printf "%i\n"
   let () = count_zeroes [1;0] |> Printf.printf "%i\n"
   let () = count_zeroes [0;1;0] |> Printf.printf "%i\n"
  -let () = count_zeroes [1;0;0;1;0] |> Printf.printf "%i\n"
  +let () = count_zeroes [0;0;0;1;0] |> Printf.printf "%i\n"
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant9" passed (see "_mutations/test.ml-mutant9.output"):
  
  --- test.ml
  +++ test.ml-mutant9
  @@ -5,4 +5,4 @@
   let () = count_zeroes [] |> Printf.printf "%i\n"
   let () = count_zeroes [1;0] |> Printf.printf "%i\n"
   let () = count_zeroes [0;1;0] |> Printf.printf "%i\n"
  -let () = count_zeroes [1;0;0;1;0] |> Printf.printf "%i\n"
  +let () = count_zeroes [1;1;0;1;0] |> Printf.printf "%i\n"
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant10" passed (see "_mutations/test.ml-mutant10.output"):
  
  --- test.ml
  +++ test.ml-mutant10
  @@ -5,4 +5,4 @@
   let () = count_zeroes [] |> Printf.printf "%i\n"
   let () = count_zeroes [1;0] |> Printf.printf "%i\n"
   let () = count_zeroes [0;1;0] |> Printf.printf "%i\n"
  -let () = count_zeroes [1;0;0;1;0] |> Printf.printf "%i\n"
  +let () = count_zeroes [1;0;1;1;0] |> Printf.printf "%i\n"
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant11" passed (see "_mutations/test.ml-mutant11.output"):
  
  --- test.ml
  +++ test.ml-mutant11
  @@ -5,4 +5,4 @@
   let () = count_zeroes [] |> Printf.printf "%i\n"
   let () = count_zeroes [1;0] |> Printf.printf "%i\n"
   let () = count_zeroes [0;1;0] |> Printf.printf "%i\n"
  -let () = count_zeroes [1;0;0;1;0] |> Printf.printf "%i\n"
  +let () = count_zeroes [1;0;0;0;0] |> Printf.printf "%i\n"
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant12" passed (see "_mutations/test.ml-mutant12.output"):
  
  --- test.ml
  +++ test.ml-mutant12
  @@ -5,4 +5,4 @@
   let () = count_zeroes [] |> Printf.printf "%i\n"
   let () = count_zeroes [1;0] |> Printf.printf "%i\n"
   let () = count_zeroes [0;1;0] |> Printf.printf "%i\n"
  -let () = count_zeroes [1;0;0;1;0] |> Printf.printf "%i\n"
  +let () = count_zeroes [1;0;0;1;1] |> Printf.printf "%i\n"
  
  ---------------------------------------------------------------------------
  



Another example that would trigger merge-of-consecutive-patterns w/GADT true:
--------------------------------------------------------------------------------

  $ cat > test.ml <<'EOF'
  > type binop = Add | Mul
  > type aexp =
  >   | X
  >   | Lit of int
  >   | Binop of aexp * binop * aexp
  > 
  > let rec interpret xval ae = match ae with
  >   | X -> xval
  >   | Lit i -> i
  >   | Binop (ae0, Add, ae1) ->
  >     let v0 = interpret xval ae0 in
  >     let v1 = interpret xval ae1 in
  >     v0 + v1
  >   | Binop (ae0, Mul, ae1) ->
  >     let v0 = interpret xval ae0 in
  >     let v1 = interpret xval ae1 in
  >     v0 * v1
  > 
  > let () = interpret 2 (Binop (Lit 1, Add, Binop (X, Mul, Lit 3))) |> Printf.printf "1 + x*3 = %i\n"
  > EOF

  $ export MUTAML_SEED=896745231
  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 5 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type binop =
    | Add 
    | Mul 
  type aexp =
    | X 
    | Lit of int 
    | Binop of aexp * binop * aexp 
  let rec interpret xval ae =
    match ae with
    | X -> xval
    | Lit i -> i
    | Binop (ae0, Add, ae1) ->
        let v0 = interpret xval ae0 in
        let v1 = interpret xval ae1 in
        if __MUTAML_MUTANT__ = (Some "test:0") then v0 - v1 else v0 + v1
    | Binop (ae0, Mul, ae1) ->
        let v0 = interpret xval ae0 in
        let v1 = interpret xval ae1 in
        if __MUTAML_MUTANT__ = (Some "test:1") then v0 + v1 else v0 * v1
  let () =
    (interpret (if __MUTAML_MUTANT__ = (Some "test:2") then 3 else 2)
       (Binop
          ((Lit (if __MUTAML_MUTANT__ = (Some "test:3") then 0 else 1)), Add,
            (Binop
               (X, Mul,
                 (Lit (if __MUTAML_MUTANT__ = (Some "test:4") then 4 else 3)))))))
      |> (Printf.printf "1 + x*3 = %i\n")


  $ _build/default/test.bc
  1 + x*3 = 7

  $ MUTAML_MUTANT="test:2" _build/default/test.bc
  1 + x*3 = 10


  $ mutaml-runner _build/default/test.bc
  read mut file test.muts
  Testing mutant test:0 ... passed
  Testing mutant test:1 ... passed
  Testing mutant test:2 ... passed
  Testing mutant test:3 ... passed
  Testing mutant test:4 ... passed
  Writing report data to mutaml-report.json

  $ mutaml-report
  Attempting to read from mutaml-report.json...
  
  Mutaml report summary:
  ----------------------
  
   target                          #mutations      #failed      #timeouts      #passed 
   -------------------------------------------------------------------------------------
   test.ml                                5       0.0%    0     0.0%    0   100.0%    5
   =====================================================================================
  
  Mutation programs passing the test suite:
  -----------------------------------------
  
  Mutation "test.ml-mutant0" passed (see "_mutations/test.ml-mutant0.output"):
  
  --- test.ml
  +++ test.ml-mutant0
  @@ -10,7 +10,7 @@
     | Binop (ae0, Add, ae1) ->
       let v0 = interpret xval ae0 in
       let v1 = interpret xval ae1 in
  -    v0 + v1
  +    v0 - v1
     | Binop (ae0, Mul, ae1) ->
       let v0 = interpret xval ae0 in
       let v1 = interpret xval ae1 in
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant1" passed (see "_mutations/test.ml-mutant1.output"):
  
  --- test.ml
  +++ test.ml-mutant1
  @@ -14,6 +14,6 @@
     | Binop (ae0, Mul, ae1) ->
       let v0 = interpret xval ae0 in
       let v1 = interpret xval ae1 in
  -    v0 * v1
  +    v0 + v1
   
   let () = interpret 2 (Binop (Lit 1, Add, Binop (X, Mul, Lit 3))) |> Printf.printf "1 + x*3 = %i\n"
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant2" passed (see "_mutations/test.ml-mutant2.output"):
  
  --- test.ml
  +++ test.ml-mutant2
  @@ -16,4 +16,4 @@
       let v1 = interpret xval ae1 in
       v0 * v1
   
  -let () = interpret 2 (Binop (Lit 1, Add, Binop (X, Mul, Lit 3))) |> Printf.printf "1 + x*3 = %i\n"
  +let () = interpret 3 (Binop (Lit 1, Add, Binop (X, Mul, Lit 3))) |> Printf.printf "1 + x*3 = %i\n"
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant3" passed (see "_mutations/test.ml-mutant3.output"):
  
  --- test.ml
  +++ test.ml-mutant3
  @@ -16,4 +16,4 @@
       let v1 = interpret xval ae1 in
       v0 * v1
   
  -let () = interpret 2 (Binop (Lit 1, Add, Binop (X, Mul, Lit 3))) |> Printf.printf "1 + x*3 = %i\n"
  +let () = interpret 2 (Binop (Lit 0, Add, Binop (X, Mul, Lit 3))) |> Printf.printf "1 + x*3 = %i\n"
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant4" passed (see "_mutations/test.ml-mutant4.output"):
  
  --- test.ml
  +++ test.ml-mutant4
  @@ -16,4 +16,4 @@
       let v1 = interpret xval ae1 in
       v0 * v1
   
  -let () = interpret 2 (Binop (Lit 1, Add, Binop (X, Mul, Lit 3))) |> Printf.printf "1 + x*3 = %i\n"
  +let () = interpret 2 (Binop (Lit 1, Add, Binop (X, Mul, Lit 4))) |> Printf.printf "1 + x*3 = %i\n"
  
  ---------------------------------------------------------------------------
  



Same example that triggers merge-of-consecutive-patterns w/GADT false:
--------------------------------------------------------------------------------

  $ dune clean

  $ export MUTAML_GADT=false
  $ export MUTAML_SEED=896745231

  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: false
  Created 6 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type binop =
    | Add 
    | Mul 
  type aexp =
    | X 
    | Lit of int 
    | Binop of aexp * binop * aexp 
  let rec interpret xval ae =
    ((match ae with
      | X -> xval
      | Lit i -> i
      | Binop (ae0, Add, ae1) when __MUTAML_MUTANT__ <> (Some "test:2") ->
          let v0 = interpret xval ae0 in
          let v1 = interpret xval ae1 in
          if __MUTAML_MUTANT__ = (Some "test:0") then v0 - v1 else v0 + v1
      | Binop (ae0, Add, ae1) | Binop (ae0, Mul, ae1) ->
          let v0 = interpret xval ae0 in
          let v1 = interpret xval ae1 in
          if __MUTAML_MUTANT__ = (Some "test:1") then v0 + v1 else v0 * v1)
    [@ocaml.warning "-8"])
  let () =
    (interpret (if __MUTAML_MUTANT__ = (Some "test:3") then 3 else 2)
       (Binop
          ((Lit (if __MUTAML_MUTANT__ = (Some "test:4") then 0 else 1)), Add,
            (Binop
               (X, Mul,
                 (Lit (if __MUTAML_MUTANT__ = (Some "test:5") then 4 else 3)))))))
      |> (Printf.printf "1 + x*3 = %i\n")


  $ _build/default/test.bc
  1 + x*3 = 7

  $ MUTAML_MUTANT="test:2" _build/default/test.bc
  1 + x*3 = 6


  $ mutaml-runner _build/default/test.bc
  read mut file test.muts
  Testing mutant test:0 ... passed
  Testing mutant test:1 ... passed
  Testing mutant test:2 ... passed
  Testing mutant test:3 ... passed
  Testing mutant test:4 ... passed
  Testing mutant test:5 ... passed
  Writing report data to mutaml-report.json

  $ mutaml-report
  Attempting to read from mutaml-report.json...
  
  Mutaml report summary:
  ----------------------
  
   target                          #mutations      #failed      #timeouts      #passed 
   -------------------------------------------------------------------------------------
   test.ml                                6       0.0%    0     0.0%    0   100.0%    6
   =====================================================================================
  
  Mutation programs passing the test suite:
  -----------------------------------------
  
  Mutation "test.ml-mutant0" passed (see "_mutations/test.ml-mutant0.output"):
  
  --- test.ml
  +++ test.ml-mutant0
  @@ -10,7 +10,7 @@
     | Binop (ae0, Add, ae1) ->
       let v0 = interpret xval ae0 in
       let v1 = interpret xval ae1 in
  -    v0 + v1
  +    v0 - v1
     | Binop (ae0, Mul, ae1) ->
       let v0 = interpret xval ae0 in
       let v1 = interpret xval ae1 in
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant1" passed (see "_mutations/test.ml-mutant1.output"):
  
  --- test.ml
  +++ test.ml-mutant1
  @@ -14,6 +14,6 @@
     | Binop (ae0, Mul, ae1) ->
       let v0 = interpret xval ae0 in
       let v1 = interpret xval ae1 in
  -    v0 * v1
  +    v0 + v1
   
   let () = interpret 2 (Binop (Lit 1, Add, Binop (X, Mul, Lit 3))) |> Printf.printf "1 + x*3 = %i\n"
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant2" passed (see "_mutations/test.ml-mutant2.output"):
  
  --- test.ml
  +++ test.ml-mutant2
  @@ -7,11 +7,7 @@
   let rec interpret xval ae = match ae with
     | X -> xval
     | Lit i -> i
  -  | Binop (ae0, Add, ae1) ->
  -    let v0 = interpret xval ae0 in
  -    let v1 = interpret xval ae1 in
  -    v0 + v1
  -  | Binop (ae0, Mul, ae1) ->
  +  | Binop (ae0, Add, ae1) | Binop (ae0, Mul, ae1) ->
       let v0 = interpret xval ae0 in
       let v1 = interpret xval ae1 in
       v0 * v1
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant3" passed (see "_mutations/test.ml-mutant3.output"):
  
  --- test.ml
  +++ test.ml-mutant3
  @@ -16,4 +16,4 @@
       let v1 = interpret xval ae1 in
       v0 * v1
   
  -let () = interpret 2 (Binop (Lit 1, Add, Binop (X, Mul, Lit 3))) |> Printf.printf "1 + x*3 = %i\n"
  +let () = interpret 3 (Binop (Lit 1, Add, Binop (X, Mul, Lit 3))) |> Printf.printf "1 + x*3 = %i\n"
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant4" passed (see "_mutations/test.ml-mutant4.output"):
  
  --- test.ml
  +++ test.ml-mutant4
  @@ -16,4 +16,4 @@
       let v1 = interpret xval ae1 in
       v0 * v1
   
  -let () = interpret 2 (Binop (Lit 1, Add, Binop (X, Mul, Lit 3))) |> Printf.printf "1 + x*3 = %i\n"
  +let () = interpret 2 (Binop (Lit 0, Add, Binop (X, Mul, Lit 3))) |> Printf.printf "1 + x*3 = %i\n"
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant5" passed (see "_mutations/test.ml-mutant5.output"):
  
  --- test.ml
  +++ test.ml-mutant5
  @@ -16,4 +16,4 @@
       let v1 = interpret xval ae1 in
       v0 * v1
   
  -let () = interpret 2 (Binop (Lit 1, Add, Binop (X, Mul, Lit 3))) |> Printf.printf "1 + x*3 = %i\n"
  +let () = interpret 2 (Binop (Lit 1, Add, Binop (X, Mul, Lit 4))) |> Printf.printf "1 + x*3 = %i\n"
  
  ---------------------------------------------------------------------------
  
  $ unset MUTAML_GADT








Another example that would trigger merge-of-consecutive-patterns:
--------------------------------------------------------------------------------

  $ cat > test.ml <<'EOF'
  > let _f x = match x with
  >   | [| |] -> 0
  >   | [| _ |] -> 1
  >   | [| _;_ |] -> 2
  >   | [| _;_;_ |] -> 3
  >   | _ when true -> 1000
  > EOF

  $ export MUTAML_SEED=896745231
  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml 2>&1 > output.txt
  $ head -n 4 output.txt && echo "ERROR MESSAGE" && tail -n 21 output.txt
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 6 mutations of test.ml
  Writing mutation info to test.muts
  ERROR MESSAGE
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let _f x =
    match x with
    | [||] -> if __MUTAML_MUTANT__ = (Some "test:0") then 1 else 0
    | [|_|] -> if __MUTAML_MUTANT__ = (Some "test:1") then 0 else 1
    | [|_;_|] -> if __MUTAML_MUTANT__ = (Some "test:2") then 3 else 2
    | [|_;_;_|] -> if __MUTAML_MUTANT__ = (Some "test:3") then 4 else 3
    | _ when if __MUTAML_MUTANT__ = (Some "test:4") then false else true ->
        if __MUTAML_MUTANT__ = (Some "test:5") then 1001 else 1000
  File "test.ml", lines 1-6, characters 11-23:
  1 | ...........match x with
  2 |   | [| |] -> 0
  3 |   | [| _ |] -> 1
  4 |   | [| _;_ |] -> 2
  5 |   | [| _;_;_ |] -> 3
  6 |   | _ when true -> 1000
  Error (warning 8 [partial-match]): this pattern-matching is not exhaustive.
  Here is an example of a case that is not matched:
  [| _ ; _ ; _ ; _ |]
  (However, some guarded clause may match this value.)



Same example but with GADT false:
--------------------------------------------------------------------------------

  $ dune clean

  $ export MUTAML_GADT=false
  $ export MUTAML_SEED=896745231

  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: false
  Created 9 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let _f x =
    ((match x with
      | [||] when __MUTAML_MUTANT__ <> (Some "test:8") ->
          if __MUTAML_MUTANT__ = (Some "test:0") then 1 else 0
      | [||] | [|_|] when __MUTAML_MUTANT__ <> (Some "test:7") ->
          if __MUTAML_MUTANT__ = (Some "test:1") then 0 else 1
      | [|_|] | [|_;_|] when __MUTAML_MUTANT__ <> (Some "test:6") ->
          if __MUTAML_MUTANT__ = (Some "test:2") then 3 else 2
      | [|_;_|] | [|_;_;_|] ->
          if __MUTAML_MUTANT__ = (Some "test:3") then 4 else 3
      | _ when if __MUTAML_MUTANT__ = (Some "test:4") then false else true ->
          if __MUTAML_MUTANT__ = (Some "test:5") then 1001 else 1000)
    [@ocaml.warning "-8"])

  $ unset MUTAML_GADT
