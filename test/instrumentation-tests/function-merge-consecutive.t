Create dune and dune-project files:
  $ bash ../write_dune_files.sh

  $ export MUTAML_SEED=896745231
  $ export MUTAML_MUT_RATE=100


An example with only conservative, GADT-safe mutations:
--------------------------------------------------------------------------------

  $ cat > test.ml <<'EOF'
  > type t = A | B | C
  > 
  > let f = function
  > | A -> "A"
  > | B -> "B"
  > | C -> "C"
  > 
  > let () = f A |> print_endline
  > let () = f B |> print_endline
  > let () = f C |> print_endline
  > EOF

  $ export MUTAML_SEED=896745231
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type t =
    | A 
    | B 
    | C 
  let f = function | A -> "A" | B -> "B" | C -> "C"
  let () = (f A) |> print_endline
  let () = (f B) |> print_endline
  let () = (f C) |> print_endline


  $ dune exec --no-build ./test.bc
  A
  B
  C



Same example but allowing GADT-unsafe mutations:
--------------------------------------------------------------------------------

  $ dune clean

  $ export MUTAML_GADT=false
  $ export MUTAML_SEED=896745231

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: false
  Created 2 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type t =
    | A 
    | B 
    | C 
  let f =
    ((function
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
   
   let f = function
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
   
   let f = function
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
  > let rec count_zeroes = function
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

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 13 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let rec count_zeroes =
    ((function
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
   let rec count_zeroes = function
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
   let rec count_zeroes = function
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
   let rec count_zeroes = function
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
  





Another example would triggers merge-of-consecutive-patterns w/GADTs true
--------------------------------------------------------------------------------

  $ cat > test.ml <<'EOF'
  > type binop = Add | Mul
  > type aexp =
  >   | X
  >   | Lit of int
  >   | Binop of aexp * binop * aexp
  > 
  > let rec interpret xval = function
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
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
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
  let rec interpret xval =
    function
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
  




Same example that triggers merge-of-consecutive-patterns w/GADTs false
--------------------------------------------------------------------------------

  $ dune clean

  $ export MUTAML_GADT=false
  $ export MUTAML_SEED=896745231

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml | sed 's/     | /    | /' | sed 's/ \{9\}l/        l/' | sed 's/(((f/((f/' | sed 's/ \{9\}i/        i/' | sed 's/v1))/v1)/'
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
  let rec interpret xval =
    ((function
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
   let rec interpret xval = function
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
