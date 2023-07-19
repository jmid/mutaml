Example with a simple if-then-else:

  $ bash write_dune_files.sh

  $ cat > test.ml <<'EOF'
  > let test x = if x then "true" else "false"
  > let () = test true  |> print_endline
  > let () = test false |> print_endline
  > EOF

  $ export MUTAML_SEED=896745231
  $ export MUTAML_MUT_RATE=100
  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 3 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let test x =
    if (if __MUTAML_MUTANT__ = (Some "test:0") then not x else x)
    then "true"
    else "false"
  let () =
    (test (if __MUTAML_MUTANT__ = (Some "test:1") then false else true)) |>
      print_endline
  let () =
    (test (if __MUTAML_MUTANT__ = (Some "test:2") then true else false)) |>
      print_endline


  $ _build/default/test.bc
  true
  false

  $ MUTAML_MUTANT="test:0" _build/default/test.bc
  false
  true


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
  @@ -1,3 +1,3 @@
  -let test x = if x then "true" else "false"
  +let test x = if not x then "true" else "false"
   let () = test true  |> print_endline
   let () = test false |> print_endline
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant1" passed (see "_mutations/test.ml-mutant1.output"):
  
  --- test.ml
  +++ test.ml-mutant1
  @@ -1,3 +1,3 @@
   let test x = if x then "true" else "false"
  -let () = test true  |> print_endline
  +let () = test false  |> print_endline
   let () = test false |> print_endline
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant2" passed (see "_mutations/test.ml-mutant2.output"):
  
  --- test.ml
  +++ test.ml-mutant2
  @@ -1,3 +1,3 @@
   let test x = if x then "true" else "false"
   let () = test true  |> print_endline
  -let () = test false |> print_endline
  +let () = test true |> print_endline
  
  ---------------------------------------------------------------------------
  





An example with nested ifs:
---------------------------

  $ cat > test.ml <<'EOF'
  > let test i =
  >   if i<0 then "negative" else
  >     if i>0 then "positive" else "zero"
  > let () = test ~-5  |> print_endline
  > let () = test 0    |> print_endline
  > let () = test 5    |> print_endline
  > EOF

  $ export MUTAML_SEED=896745231
  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 7 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let test i =
    if
      let __MUTAML_TMP1__ =
        i < (if __MUTAML_MUTANT__ = (Some "test:0") then 1 else 0) in
      (if __MUTAML_MUTANT__ = (Some "test:3")
       then not __MUTAML_TMP1__
       else __MUTAML_TMP1__)
    then "negative"
    else
      if
        (let __MUTAML_TMP0__ =
           i > (if __MUTAML_MUTANT__ = (Some "test:1") then 1 else 0) in
         if __MUTAML_MUTANT__ = (Some "test:2")
         then not __MUTAML_TMP0__
         else __MUTAML_TMP0__)
      then "positive"
      else "zero"
  let () =
    (test (- (if __MUTAML_MUTANT__ = (Some "test:4") then 6 else 5))) |>
      print_endline
  let () =
    (test (if __MUTAML_MUTANT__ = (Some "test:5") then 1 else 0)) |>
      print_endline
  let () =
    (test (if __MUTAML_MUTANT__ = (Some "test:6") then 6 else 5)) |>
      print_endline


  $ _build/default/test.bc
  negative
  zero
  positive

  $ MUTAML_MUTANT="test:3" _build/default/test.bc
  zero
  negative
  negative

  $ MUTAML_MUTANT="test:2" _build/default/test.bc
  negative
  positive
  zero



  $ mutaml-runner _build/default/test.bc
  read mut file test.muts
  Testing mutant test:0 ... passed
  Testing mutant test:1 ... passed
  Testing mutant test:2 ... passed
  Testing mutant test:3 ... passed
  Testing mutant test:4 ... passed
  Testing mutant test:5 ... passed
  Testing mutant test:6 ... passed
  Writing report data to mutaml-report.json


  $ mutaml-report
  Attempting to read from mutaml-report.json...
  
  Mutaml report summary:
  ----------------------
  
   target                          #mutations      #failed      #timeouts      #passed 
   -------------------------------------------------------------------------------------
   test.ml                                7       0.0%    0     0.0%    0   100.0%    7
   =====================================================================================
  
  Mutation programs passing the test suite:
  -----------------------------------------
  
  Mutation "test.ml-mutant0" passed (see "_mutations/test.ml-mutant0.output"):
  
  --- test.ml
  +++ test.ml-mutant0
  @@ -1,5 +1,5 @@
   let test i =
  -  if i<0 then "negative" else
  +  if i<1 then "negative" else
       if i>0 then "positive" else "zero"
   let () = test ~-5  |> print_endline
   let () = test 0    |> print_endline
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant1" passed (see "_mutations/test.ml-mutant1.output"):
  
  --- test.ml
  +++ test.ml-mutant1
  @@ -1,6 +1,6 @@
   let test i =
     if i<0 then "negative" else
  -    if i>0 then "positive" else "zero"
  +    if i>1 then "positive" else "zero"
   let () = test ~-5  |> print_endline
   let () = test 0    |> print_endline
   let () = test 5    |> print_endline
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant2" passed (see "_mutations/test.ml-mutant2.output"):
  
  --- test.ml
  +++ test.ml-mutant2
  @@ -1,6 +1,6 @@
   let test i =
     if i<0 then "negative" else
  -    if i>0 then "positive" else "zero"
  +    if not (i > 0) then "positive" else "zero"
   let () = test ~-5  |> print_endline
   let () = test 0    |> print_endline
   let () = test 5    |> print_endline
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant3" passed (see "_mutations/test.ml-mutant3.output"):
  
  --- test.ml
  +++ test.ml-mutant3
  @@ -1,5 +1,5 @@
   let test i =
  -  if i<0 then "negative" else
  +  if not (i < 0) then "negative" else
       if i>0 then "positive" else "zero"
   let () = test ~-5  |> print_endline
   let () = test 0    |> print_endline
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant4" passed (see "_mutations/test.ml-mutant4.output"):
  
  --- test.ml
  +++ test.ml-mutant4
  @@ -1,6 +1,6 @@
   let test i =
     if i<0 then "negative" else
       if i>0 then "positive" else "zero"
  -let () = test ~-5  |> print_endline
  +let () = test ~-6  |> print_endline
   let () = test 0    |> print_endline
   let () = test 5    |> print_endline
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant5" passed (see "_mutations/test.ml-mutant5.output"):
  
  --- test.ml
  +++ test.ml-mutant5
  @@ -2,5 +2,5 @@
     if i<0 then "negative" else
       if i>0 then "positive" else "zero"
   let () = test ~-5  |> print_endline
  -let () = test 0    |> print_endline
  +let () = test 1    |> print_endline
   let () = test 5    |> print_endline
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant6" passed (see "_mutations/test.ml-mutant6.output"):
  
  --- test.ml
  +++ test.ml-mutant6
  @@ -3,4 +3,4 @@
       if i>0 then "positive" else "zero"
   let () = test ~-5  |> print_endline
   let () = test 0    |> print_endline
  -let () = test 5    |> print_endline
  +let () = test 6    |> print_endline
  
  ---------------------------------------------------------------------------
  
