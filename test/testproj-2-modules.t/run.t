  $ ls src test
  src:
  dune
  lib1.ml
  lib2.ml
  main.ml
  
  test:
  dune
  ounittest.ml


  $ echo "(lang dune 2.9)" > dune-project

Set seed and (full) mutation rate as environment variables, for repeatability
  $ export MUTAML_SEED=896745231
  $ export MUTAML_MUT_RATE=100

  $ dune build test/ounittest.exe --instrument-with mutaml
  Running mutaml instrumentation on "src/lib1.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 3 mutations of src/lib1.ml
  Writing mutation info to src/lib1.muts
  Running mutaml instrumentation on "src/lib2.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 6 mutations of src/lib2.ml
  Writing mutation info to src/lib2.muts

  $ mutaml-runner _build/default/test/ounittest.exe
  read mut file src/lib1.muts
  read mut file src/lib2.muts
  Testing mutant src/lib1:0 ... failed
  Testing mutant src/lib1:1 ... failed
  Testing mutant src/lib1:2 ... failed
  Testing mutant src/lib2:0 ... passed
  Testing mutant src/lib2:1 ... passed
  Testing mutant src/lib2:2 ... passed
  Testing mutant src/lib2:3 ... failed
  Testing mutant src/lib2:4 ... failed
  Testing mutant src/lib2:5 ... failed
  Writing report data to mutaml-report.json

  $ mutaml-report
  Attempting to read from mutaml-report.json...
  
  Mutaml report summary:
  ----------------------
  
   target                          #mutations      #failed      #timeouts      #passed 
   -------------------------------------------------------------------------------------
   src/lib1.ml                            3     100.0%    3     0.0%    0     0.0%    0
   src/lib2.ml                            6      50.0%    3     0.0%    0    50.0%    3
   -------------------------------------------------------------------------------------
   total                                  9      66.7%    6     0.0%    0    33.3%    3
   =====================================================================================
  
  Mutation programs passing the test suite:
  -----------------------------------------
  
  Mutation "src/lib2.ml-mutant0" passed (see "_mutations/src/lib2.ml-mutant0.output"):
  
  --- src/lib2.ml
  +++ src/lib2.ml-mutant0
  @@ -1,5 +1,5 @@
   let rec fac n = match n with
  -  | 0 -> 1
  +  | 0 -> 0
     | _ -> n * fac (n-1)
   
   let rec sum n = match n with
  
  ---------------------------------------------------------------------------
  
  Mutation "src/lib2.ml-mutant1" passed (see "_mutations/src/lib2.ml-mutant1.output"):
  
  --- src/lib2.ml
  +++ src/lib2.ml-mutant1
  @@ -1,6 +1,6 @@
   let rec fac n = match n with
     | 0 -> 1
  -  | _ -> n * fac (n-1)
  +  | _ -> n * fac n
   
   let rec sum n = match n with
     | 0 -> 0
  
  ---------------------------------------------------------------------------
  
  Mutation "src/lib2.ml-mutant2" passed (see "_mutations/src/lib2.ml-mutant2.output"):
  
  --- src/lib2.ml
  +++ src/lib2.ml-mutant2
  @@ -1,6 +1,6 @@
   let rec fac n = match n with
     | 0 -> 1
  -  | _ -> n * fac (n-1)
  +  | _ -> n + (fac (n - 1))
   
   let rec sum n = match n with
     | 0 -> 0
  
  ---------------------------------------------------------------------------
  
