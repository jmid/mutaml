Create dune and dune-project files:
  $ bash ../write_dune_files.sh

Set seed and (full) mutation rate as environment variables, for repeatability
  $ export MUTAML_SEED=896745231
  $ export MUTAML_MUT_RATE=100

Make an .ml-file:
  $ cat > test.ml <<'EOF'
  > let identify_char = function
  >   | 'a'..'z' -> "lower-case letter"
  >   | 'A'..'Z' -> "upper-case letter"
  >   | '0'..'9' -> "digit"
  >   | _        -> "other"
  > let () = print_endline (identify_char 'e')
  > let () = print_endline (identify_char 'U')
  > let () = print_endline (identify_char '5')
  > let () = print_endline (identify_char '_')
  > EOF


  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 3 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let identify_char =
    ((function
      | 'a'..'z' when __MUTAML_MUTANT__ <> (Some "test:2") ->
          "lower-case letter"
      | 'A'..'Z' when __MUTAML_MUTANT__ <> (Some "test:1") ->
          "upper-case letter"
      | '0'..'9' when __MUTAML_MUTANT__ <> (Some "test:0") -> "digit"
      | _ -> "other")
    [@ocaml.warning "-8"])
  let () = print_endline (identify_char 'e')
  let () = print_endline (identify_char 'U')
  let () = print_endline (identify_char '5')
  let () = print_endline (identify_char '_')


  $ _build/default/test.bc
  lower-case letter
  upper-case letter
  digit
  other

  $ MUTAML_MUTANT="test:0" _build/default/test.bc
  lower-case letter
  upper-case letter
  other
  other

  $ MUTAML_MUTANT="test:1" _build/default/test.bc
  lower-case letter
  other
  digit
  other

  $ MUTAML_MUTANT="test:2" _build/default/test.bc
  other
  upper-case letter
  digit
  other


Start runner and generate report to ensure mutants print correctly:

  $ mutaml-runner _build/default/test.bc
  read mut file test.muts
  Testing mutant test:0 ... passed
  Testing mutant test:1 ... passed
  Testing mutant test:2 ... passed
  Writing report data to mutaml-report.json


  $ mutaml-report
  Attempting to read from mutaml-report.json...
  
  Mutaml report summary:
  ----------------------
  
   target                          #mutations      #failed      #timeouts      #passed 
   -------------------------------------------------------------------------------------
   test.ml                                3       0.0%    0     0.0%    0   100.0%    3
   =====================================================================================
  
  Mutation programs passing the test suite:
  -----------------------------------------
  
  Mutation "test.ml-mutant0" passed (see "_mutations/test.ml-mutant0.output"):
  
  --- test.ml
  +++ test.ml-mutant0
  @@ -1,7 +1,6 @@
   let identify_char = function
     | 'a'..'z' -> "lower-case letter"
     | 'A'..'Z' -> "upper-case letter"
  -  | '0'..'9' -> "digit"
     | _        -> "other"
   let () = print_endline (identify_char 'e')
   let () = print_endline (identify_char 'U')
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant1" passed (see "_mutations/test.ml-mutant1.output"):
  
  --- test.ml
  +++ test.ml-mutant1
  @@ -1,6 +1,5 @@
   let identify_char = function
     | 'a'..'z' -> "lower-case letter"
  -  | 'A'..'Z' -> "upper-case letter"
     | '0'..'9' -> "digit"
     | _        -> "other"
   let () = print_endline (identify_char 'e')
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant2" passed (see "_mutations/test.ml-mutant2.output"):
  
  --- test.ml
  +++ test.ml-mutant2
  @@ -1,5 +1,4 @@
   let identify_char = function
  -  | 'a'..'z' -> "lower-case letter"
     | 'A'..'Z' -> "upper-case letter"
     | '0'..'9' -> "digit"
     | _        -> "other"
  
  ---------------------------------------------------------------------------
  


Test that same example with a variable will be instrumented with this mutation:
--------------------------------------------------------------------------------

  $ cat > test.ml <<'EOF'
  > let identify_char = function
  >   | 'a'..'z' -> "lower-case letter"
  >   | 'A'..'Z' -> "upper-case letter"
  >   | '0'..'9' -> "digit"
  >   | c        -> "other char: " ^ String.make 1 c
  > let () = print_endline (identify_char 'e')
  > let () = print_endline (identify_char 'U')
  > let () = print_endline (identify_char '5')
  > let () = print_endline (identify_char '_')
  > EOF


  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 4 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let identify_char =
    ((function
      | 'a'..'z' when __MUTAML_MUTANT__ <> (Some "test:3") ->
          "lower-case letter"
      | 'A'..'Z' when __MUTAML_MUTANT__ <> (Some "test:2") ->
          "upper-case letter"
      | '0'..'9' when __MUTAML_MUTANT__ <> (Some "test:1") -> "digit"
      | c ->
          "other char: " ^
            (String.make (if __MUTAML_MUTANT__ = (Some "test:0") then 0 else 1)
               c))
    [@ocaml.warning "-8"])
  let () = print_endline (identify_char 'e')
  let () = print_endline (identify_char 'U')
  let () = print_endline (identify_char '5')
  let () = print_endline (identify_char '_')


  $ _build/default/test.bc
  lower-case letter
  upper-case letter
  digit
  other char: _

  $ MUTAML_MUTANT="test:0" _build/default/test.bc
  lower-case letter
  upper-case letter
  digit
  other char: 

  $ MUTAML_MUTANT="test:1" _build/default/test.bc
  lower-case letter
  upper-case letter
  other char: 5
  other char: _

  $ MUTAML_MUTANT="test:2" _build/default/test.bc
  lower-case letter
  other char: U
  digit
  other char: _

  $ MUTAML_MUTANT="test:3" _build/default/test.bc
  other char: e
  upper-case letter
  digit
  other char: _



  $ mutaml-runner _build/default/test.bc
  read mut file test.muts
  Testing mutant test:0 ... passed
  Testing mutant test:1 ... passed
  Testing mutant test:2 ... passed
  Testing mutant test:3 ... passed
  Writing report data to mutaml-report.json


  $ mutaml-report
  Attempting to read from mutaml-report.json...
  
  Mutaml report summary:
  ----------------------
  
   target                          #mutations      #failed      #timeouts      #passed 
   -------------------------------------------------------------------------------------
   test.ml                                4       0.0%    0     0.0%    0   100.0%    4
   =====================================================================================
  
  Mutation programs passing the test suite:
  -----------------------------------------
  
  Mutation "test.ml-mutant0" passed (see "_mutations/test.ml-mutant0.output"):
  
  --- test.ml
  +++ test.ml-mutant0
  @@ -2,7 +2,7 @@
     | 'a'..'z' -> "lower-case letter"
     | 'A'..'Z' -> "upper-case letter"
     | '0'..'9' -> "digit"
  -  | c        -> "other char: " ^ String.make 1 c
  +  | c        -> "other char: " ^ String.make 0 c
   let () = print_endline (identify_char 'e')
   let () = print_endline (identify_char 'U')
   let () = print_endline (identify_char '5')
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant1" passed (see "_mutations/test.ml-mutant1.output"):
  
  --- test.ml
  +++ test.ml-mutant1
  @@ -1,7 +1,6 @@
   let identify_char = function
     | 'a'..'z' -> "lower-case letter"
     | 'A'..'Z' -> "upper-case letter"
  -  | '0'..'9' -> "digit"
     | c        -> "other char: " ^ String.make 1 c
   let () = print_endline (identify_char 'e')
   let () = print_endline (identify_char 'U')
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant2" passed (see "_mutations/test.ml-mutant2.output"):
  
  --- test.ml
  +++ test.ml-mutant2
  @@ -1,6 +1,5 @@
   let identify_char = function
     | 'a'..'z' -> "lower-case letter"
  -  | 'A'..'Z' -> "upper-case letter"
     | '0'..'9' -> "digit"
     | c        -> "other char: " ^ String.make 1 c
   let () = print_endline (identify_char 'e')
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant3" passed (see "_mutations/test.ml-mutant3.output"):
  
  --- test.ml
  +++ test.ml-mutant3
  @@ -1,5 +1,4 @@
   let identify_char = function
  -  | 'a'..'z' -> "lower-case letter"
     | 'A'..'Z' -> "upper-case letter"
     | '0'..'9' -> "digit"
     | c        -> "other char: " ^ String.make 1 c
  
  ---------------------------------------------------------------------------
  


Another test w/tuples and wildcards:
--------------------------------------------------------------------------------

  $ cat > test.ml <<'EOF'
  > let prioritize fallback = function
  >   | Some x, _  -> x
  >   | _, Some y  -> y
  >   | _, _       -> fallback;;
  > prioritize "3rd" (Some "1st",Some "2nd") |> print_endline;;
  > prioritize "3rd" (Some "1st",None      ) |> print_endline;;
  > prioritize "3rd" (None      ,Some "2nd") |> print_endline;;
  > prioritize "3rd" (None      ,None      ) |> print_endline
  > EOF

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 2 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let prioritize fallback =
    function
    | (Some x, _) when __MUTAML_MUTANT__ <> (Some "test:1") -> x
    | (_, Some y) when __MUTAML_MUTANT__ <> (Some "test:0") -> y
    | (_, _) -> fallback
  ;;(prioritize "3rd" ((Some "1st"), (Some "2nd"))) |> print_endline
  ;;(prioritize "3rd" ((Some "1st"), None)) |> print_endline
  ;;(prioritize "3rd" (None, (Some "2nd"))) |> print_endline
  ;;(prioritize "3rd" (None, None)) |> print_endline

  $ _build/default/test.bc
  1st
  1st
  2nd
  3rd

  $ MUTAML_MUTANT="test:0" _build/default/test.bc
  1st
  1st
  3rd
  3rd

  $ MUTAML_MUTANT="test:1" _build/default/test.bc
  2nd
  3rd
  2nd
  3rd


Start runner and generate report to ensure mutants print correctly:

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
  @@ -1,6 +1,5 @@
   let prioritize fallback = function
     | Some x, _  -> x
  -  | _, Some y  -> y
     | _, _       -> fallback;;
   prioritize "3rd" (Some "1st",Some "2nd") |> print_endline;;
   prioritize "3rd" (Some "1st",None      ) |> print_endline;;
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant1" passed (see "_mutations/test.ml-mutant1.output"):
  
  --- test.ml
  +++ test.ml-mutant1
  @@ -1,5 +1,4 @@
   let prioritize fallback = function
  -  | Some x, _  -> x
     | _, Some y  -> y
     | _, _       -> fallback;;
   prioritize "3rd" (Some "1st",Some "2nd") |> print_endline;;
  
  ---------------------------------------------------------------------------
  


Same example without wildcards will not be instrumented with this mutation:
--------------------------------------------------------------------------------

  $ cat > test.ml <<'EOF'
  > let prioritize fallback = function
  >   | Some x, _  -> x
  >   | _, Some y  -> y
  >   | None, None -> fallback;;
  > prioritize "3rd" (Some "1st",Some "2nd") |> print_endline;;
  > prioritize "3rd" (Some "1st",None      ) |> print_endline;;
  > prioritize "3rd" (None      ,Some "2nd") |> print_endline;;
  > prioritize "3rd" (None      ,None      ) |> print_endline
  > EOF


  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let prioritize fallback =
    function | (Some x, _) -> x | (_, Some y) -> y | (None, None) -> fallback
  ;;(prioritize "3rd" ((Some "1st"), (Some "2nd"))) |> print_endline
  ;;(prioritize "3rd" ((Some "1st"), None)) |> print_endline
  ;;(prioritize "3rd" (None, (Some "2nd"))) |> print_endline
  ;;(prioritize "3rd" (None, None)) |> print_endline
