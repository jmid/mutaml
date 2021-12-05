Tests mutating sequence expressions
===================================

  $ bash write_dune_files.sh

Set seed and (full) mutation rate as environment variables, for repeatability
  $ export MUTAML_SEED=896745231
  $ export MUTAML_MUT_RATE=100


Test a sequence mutation:
-------------------------

  $ cat > test.ml <<'EOF'
  > let f () =
  >   let c = ref 0 in
  >   begin
  >     incr c;
  >     incr c;
  >     incr c;
  >     !c
  >   end;;
  > assert (f() = 3)
  > EOF

  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 4 mutations of test.ml
  Writing mutation info to test.muts
        ocamlc .test.eobjs/byte/dune__exe__Test.{cmi,cmo,cmt}
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let f () =
    let c = ref (if __MUTAML_MUTANT__ = (Some "test:0") then 1 else 0) in
    if __MUTAML_MUTANT__ = (Some "test:3") then () else incr c;
    if __MUTAML_MUTANT__ = (Some "test:2") then () else incr c;
    if __MUTAML_MUTANT__ = (Some "test:1") then () else incr c;
    !c
  ;;assert ((f ()) = 3)


Check that instrumentation hasn't changed the program's behaviour
  $ dune exec --no-build ./test.bc


  $ MUTAML_MUTANT="test:0" dune exec --no-build ./test.bc
  Fatal error: exception Assert_failure("test.ml", 9, 0)
  [2]

  $ MUTAML_MUTANT="test:1" dune exec --no-build ./test.bc
  Fatal error: exception Assert_failure("test.ml", 9, 0)
  [2]

  $ MUTAML_MUTANT="test:2" dune exec --no-build ./test.bc
  Fatal error: exception Assert_failure("test.ml", 9, 0)
  [2]

  $ MUTAML_MUTANT="test:3" dune exec --no-build ./test.bc
  Fatal error: exception Assert_failure("test.ml", 9, 0)
  [2]


  $ mutaml-runner _build/default/test.bc
  read mut file test.muts
  Testing mutant test:0 ... failed
  Testing mutant test:1 ... failed
  Testing mutant test:2 ... failed
  Testing mutant test:3 ... failed
  Writing report data to mutaml-report.json




Test uncaught sequence mutation:
--------------------------------

  $ cat > test.ml <<'EOF'
  > let f () =
  >   let c = ref 0 in
  >   begin
  >     incr c;
  >     incr c;
  >     incr c;
  >     !c
  >   end;;
  > assert (f() > 0)
  > EOF

  $ bash filter_dune_build.sh ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 4 mutations of test.ml
  Writing mutation info to test.muts
        ocamlc .test.eobjs/byte/dune__exe__Test.{cmi,cmo,cmt}
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let f () =
    let c = ref (if __MUTAML_MUTANT__ = (Some "test:0") then 1 else 0) in
    if __MUTAML_MUTANT__ = (Some "test:3") then () else incr c;
    if __MUTAML_MUTANT__ = (Some "test:2") then () else incr c;
    if __MUTAML_MUTANT__ = (Some "test:1") then () else incr c;
    !c
  ;;assert ((f ()) > 0)


Check that instrumentation hasn't changed the program's behaviour
  $ dune exec --no-build ./test.bc


  $ MUTAML_MUTANT="test:0" dune exec --no-build ./test.bc

  $ MUTAML_MUTANT="test:1" dune exec --no-build ./test.bc

  $ MUTAML_MUTANT="test:2" dune exec --no-build ./test.bc

  $ MUTAML_MUTANT="test:3" dune exec --no-build ./test.bc


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
  @@ -1,5 +1,5 @@
   let f () =
  -  let c = ref 0 in
  +  let c = ref 1 in
     begin
       incr c;
       incr c;
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant1" passed (see "_mutations/test.ml-mutant1.output"):
  
  --- test.ml
  +++ test.ml-mutant1
  @@ -3,7 +3,6 @@
     begin
       incr c;
       incr c;
  -    incr c;
       !c
     end;;
   assert (f() > 0)
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant2" passed (see "_mutations/test.ml-mutant2.output"):
  
  --- test.ml
  +++ test.ml-mutant2
  @@ -2,8 +2,6 @@
     let c = ref 0 in
     begin
       incr c;
  -    incr c;
  -    incr c;
  -    !c
  +    incr c; !c
     end;;
   assert (f() > 0)
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant3" passed (see "_mutations/test.ml-mutant3.output"):
  
  --- test.ml
  +++ test.ml-mutant3
  @@ -1,9 +1,4 @@
   let f () =
     let c = ref 0 in
  -  begin
  -    incr c;
  -    incr c;
  -    incr c;
  -    !c
  -  end;;
  +  incr c; incr c; !c;;
   assert (f() > 0)
  
  ---------------------------------------------------------------------------
  
