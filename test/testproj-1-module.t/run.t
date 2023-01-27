Let us try something:

  $ ls *.ml
  lib.ml
  main.ml
  ounittest.ml

  $ echo "(lang dune 2.9)" > dune-project

  $ cat > dune <<'EOF'
  > (library
  >  (name lib)
  >  (modules lib)
  >  (libraries stdlib-random.v4)
  >  (instrumentation (backend mutaml))
  > )
  > 
  > (executable
  >  (name main)
  >  (modules main)
  >  (libraries lib)
  > )
  > 
  > (test
  >   (name ounittest)
  >   (modules ounittest)
  >   (libraries lib ounit2)
  > )
  > EOF

Check that files were created as expected:
  $ ls dune* *.ml
  dune
  dune-project
  lib.ml
  main.ml
  ounittest.ml

Set seed and (full) mutation rate as environment variables, for repeatability
  $ export MUTAML_SEED=896745231
  $ export MUTAML_MUT_RATE=100

  $ dune build ./ounittest.exe --instrument-with mutaml
  Running mutaml instrumentation on "lib.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 13 mutations of lib.ml
  Writing mutation info to lib.muts

  $ ls _build/default
  lib.a
  lib.cmxa
  lib.ml
  lib.muts
  lib.pp.ml
  mutaml-mut-files.txt
  ounittest.exe
  ounittest.ml

  $ mutaml-runner _build/default/ounittest.exe
  read mut file lib.muts
  Testing mutant lib:0 ... failed
  Testing mutant lib:1 ... failed
  Testing mutant lib:2 ... failed
  Testing mutant lib:3 ... failed
  Testing mutant lib:4 ... failed
  Testing mutant lib:5 ... failed
  Testing mutant lib:6 ... passed
  Testing mutant lib:7 ... failed
  Testing mutant lib:8 ... failed
  Testing mutant lib:9 ... failed
  Testing mutant lib:10 ... failed
  Testing mutant lib:11 ... failed
  Testing mutant lib:12 ... passed
  Writing report data to mutaml-report.json

  $ mutaml-report mutaml-report.json
  Attempting to read from mutaml-report.json...
  
  Mutaml report summary:
  ----------------------
  
   target                          #mutations      #failed      #timeouts      #passed 
   -------------------------------------------------------------------------------------
   lib.ml                                13      84.6%   11     0.0%    0    15.4%    2
   =====================================================================================
  
  Mutation programs passing the test suite:
  -----------------------------------------
  
  Mutation "lib.ml-mutant6" passed (see "_mutations/lib.ml-mutant6.output"):
  
  --- lib.ml
  +++ lib.ml-mutant6
  @@ -21,7 +21,7 @@
   
   let pi total =
     let rec loop n inside =
  -    if n = 0 then
  +    if n = 1 then
         4. *. (float_of_int inside /. float_of_int total)
       else
         let x = 1.0 -. Random.float 2.0 in
  
  ---------------------------------------------------------------------------
  
  Mutation "lib.ml-mutant12" passed (see "_mutations/lib.ml-mutant12.output"):
  
  --- lib.ml
  +++ lib.ml-mutant12
  @@ -30,4 +30,4 @@
         then loop (n-1) (inside+1)
         else loop (n-1) (inside)
     in
  -  loop total 0
  +  loop total 1
  
  ---------------------------------------------------------------------------
  


Restarting runner should give the same output:

  $ mutaml-runner _build/default/ounittest.exe
  read mut file lib.muts
  Testing mutant lib:0 ... failed
  Testing mutant lib:1 ... failed
  Testing mutant lib:2 ... failed
  Testing mutant lib:3 ... failed
  Testing mutant lib:4 ... failed
  Testing mutant lib:5 ... failed
  Testing mutant lib:6 ... passed
  Testing mutant lib:7 ... failed
  Testing mutant lib:8 ... failed
  Testing mutant lib:9 ... failed
  Testing mutant lib:10 ... failed
  Testing mutant lib:11 ... failed
  Testing mutant lib:12 ... passed
  Writing report data to mutaml-report.json


  $ mutaml-runner _build/default/ounittest.exe
  read mut file lib.muts
  Testing mutant lib:0 ... failed
  Testing mutant lib:1 ... failed
  Testing mutant lib:2 ... failed
  Testing mutant lib:3 ... failed
  Testing mutant lib:4 ... failed
  Testing mutant lib:5 ... failed
  Testing mutant lib:6 ... passed
  Testing mutant lib:7 ... failed
  Testing mutant lib:8 ... failed
  Testing mutant lib:9 ... failed
  Testing mutant lib:10 ... failed
  Testing mutant lib:11 ... failed
  Testing mutant lib:12 ... passed
  Writing report data to mutaml-report.json


Similarly for the reporter:

  $ mutaml-report mutaml-report.json
  Attempting to read from mutaml-report.json...
  
  Mutaml report summary:
  ----------------------
  
   target                          #mutations      #failed      #timeouts      #passed 
   -------------------------------------------------------------------------------------
   lib.ml                                13      84.6%   11     0.0%    0    15.4%    2
   =====================================================================================
  
  Mutation programs passing the test suite:
  -----------------------------------------
  
  Mutation "lib.ml-mutant6" passed (see "_mutations/lib.ml-mutant6.output"):
  
  --- lib.ml
  +++ lib.ml-mutant6
  @@ -21,7 +21,7 @@
   
   let pi total =
     let rec loop n inside =
  -    if n = 0 then
  +    if n = 1 then
         4. *. (float_of_int inside /. float_of_int total)
       else
         let x = 1.0 -. Random.float 2.0 in
  
  ---------------------------------------------------------------------------
  
  Mutation "lib.ml-mutant12" passed (see "_mutations/lib.ml-mutant12.output"):
  
  --- lib.ml
  +++ lib.ml-mutant12
  @@ -30,4 +30,4 @@
         then loop (n-1) (inside+1)
         else loop (n-1) (inside)
     in
  -  loop total 0
  +  loop total 1
  
  ---------------------------------------------------------------------------
  

Try a second run to check that we get the same:

  $ mutaml-report mutaml-report.json
  Attempting to read from mutaml-report.json...
  
  Mutaml report summary:
  ----------------------
  
   target                          #mutations      #failed      #timeouts      #passed 
   -------------------------------------------------------------------------------------
   lib.ml                                13      84.6%   11     0.0%    0    15.4%    2
   =====================================================================================
  
  Mutation programs passing the test suite:
  -----------------------------------------
  
  Mutation "lib.ml-mutant6" passed (see "_mutations/lib.ml-mutant6.output"):
  
  --- lib.ml
  +++ lib.ml-mutant6
  @@ -21,7 +21,7 @@
   
   let pi total =
     let rec loop n inside =
  -    if n = 0 then
  +    if n = 1 then
         4. *. (float_of_int inside /. float_of_int total)
       else
         let x = 1.0 -. Random.float 2.0 in
  
  ---------------------------------------------------------------------------
  
  Mutation "lib.ml-mutant12" passed (see "_mutations/lib.ml-mutant12.output"):
  
  --- lib.ml
  +++ lib.ml-mutant12
  @@ -30,4 +30,4 @@
         then loop (n-1) (inside+1)
         else loop (n-1) (inside)
     in
  -  loop total 0
  +  loop total 1
  
  ---------------------------------------------------------------------------
  


Try without providing an explicit file name:

  $ mutaml-report
  Attempting to read from mutaml-report.json...
  
  Mutaml report summary:
  ----------------------
  
   target                          #mutations      #failed      #timeouts      #passed 
   -------------------------------------------------------------------------------------
   lib.ml                                13      84.6%   11     0.0%    0    15.4%    2
   =====================================================================================
  
  Mutation programs passing the test suite:
  -----------------------------------------
  
  Mutation "lib.ml-mutant6" passed (see "_mutations/lib.ml-mutant6.output"):
  
  --- lib.ml
  +++ lib.ml-mutant6
  @@ -21,7 +21,7 @@
   
   let pi total =
     let rec loop n inside =
  -    if n = 0 then
  +    if n = 1 then
         4. *. (float_of_int inside /. float_of_int total)
       else
         let x = 1.0 -. Random.float 2.0 in
  
  ---------------------------------------------------------------------------
  
  Mutation "lib.ml-mutant12" passed (see "_mutations/lib.ml-mutant12.output"):
  
  --- lib.ml
  +++ lib.ml-mutant12
  @@ -30,4 +30,4 @@
         then loop (n-1) (inside+1)
         else loop (n-1) (inside)
     in
  -  loop total 0
  +  loop total 1
  
  ---------------------------------------------------------------------------
  


Now try the -no-diff option while providing an explicit file name:

  $ mutaml-report -no-diff mutaml-report.json
  Attempting to read from mutaml-report.json...
  
  Mutaml report summary:
  ----------------------
  
   target                          #mutations      #failed      #timeouts      #passed 
   -------------------------------------------------------------------------------------
   lib.ml                                13      84.6%   11     0.0%    0    15.4%    2
   =====================================================================================
  
  Mutation programs passing the test suite:
  -----------------------------------------
  
  Mutation "lib.ml-mutant6" passed (see "_mutations/lib.ml-mutant6.output")
  Mutation "lib.ml-mutant12" passed (see "_mutations/lib.ml-mutant12.output")


--------------------------------------------------------------------------------


And try the -no-diff option without providing an explicit file name:

  $ mutaml-report -no-diff
  Attempting to read from mutaml-report.json...
  
  Mutaml report summary:
  ----------------------
  
   target                          #mutations      #failed      #timeouts      #passed 
   -------------------------------------------------------------------------------------
   lib.ml                                13      84.6%   11     0.0%    0    15.4%    2
   =====================================================================================
  
  Mutation programs passing the test suite:
  -----------------------------------------
  
  Mutation "lib.ml-mutant6" passed (see "_mutations/lib.ml-mutant6.output")
  Mutation "lib.ml-mutant12" passed (see "_mutations/lib.ml-mutant12.output")


--------------------------------------------------------------------------------


Now move file to a different name and retry the -no-diff option with the new name:

  $ mv mutaml-report.json some-report-name.json
  $ mutaml-report -no-diff some-report-name.json
  Attempting to read from some-report-name.json...
  
  Mutaml report summary:
  ----------------------
  
   target                          #mutations      #failed      #timeouts      #passed 
   -------------------------------------------------------------------------------------
   lib.ml                                13      84.6%   11     0.0%    0    15.4%    2
   =====================================================================================
  
  Mutation programs passing the test suite:
  -----------------------------------------
  
  Mutation "lib.ml-mutant6" passed (see "_mutations/lib.ml-mutant6.output")
  Mutation "lib.ml-mutant12" passed (see "_mutations/lib.ml-mutant12.output")


--------------------------------------------------------------------------------

Now test with another build context than _build/default:
--------------------------------------------------------

Create a dune-workspace file with another build context:
  $ cat > dune-workspace <<'EOF'
  > (lang dune 2.9)
  > (context default)
  > (context (default (name mutation) (instrument_with mutaml)))
  > EOF


  $ dune clean
  $ unset MUTAML_MUT_RATE
  $ export MUTAML_SEED=896745231
  $ dune build ./ounittest.exe
  Running mutaml instrumentation on "lib.ml"
  Randomness seed: 896745231   Mutation rate: 50   GADTs enabled: true
  Created 9 mutations of lib.ml
  Writing mutation info to lib.muts

  $ ls _* dune* *.ml some-report-name.json
  dune
  dune-project
  dune-workspace
  lib.ml
  main.ml
  ounittest.ml
  some-report-name.json
  
  _build:
  default
  log
  mutation
  
  _mutations:
  lib.ml-mutant12
  lib.ml-mutant6
  lib.muts-mutant0.output
  lib.muts-mutant1.output
  lib.muts-mutant10.output
  lib.muts-mutant11.output
  lib.muts-mutant12.output
  lib.muts-mutant2.output
  lib.muts-mutant3.output
  lib.muts-mutant4.output
  lib.muts-mutant5.output
  lib.muts-mutant6.output
  lib.muts-mutant7.output
  lib.muts-mutant8.output
  lib.muts-mutant9.output

  $ ls _build/default
  lib.a
  lib.cmxa
  lib.ml
  ounittest.exe
  ounittest.ml

  $ ls _build/mutation
  lib.a
  lib.cmxa
  lib.ml
  lib.muts
  lib.pp.ml
  mutaml-mut-files.txt
  ounittest.exe
  ounittest.ml

  $ export MUTAML_BUILD_CONTEXT="_build/mutation"
  $ mutaml-runner _build/mutation/ounittest.exe
  read mut file lib.muts
  Testing mutant lib:0 ... failed
  Testing mutant lib:1 ... failed
  Testing mutant lib:2 ... failed
  Testing mutant lib:3 ... failed
  Testing mutant lib:4 ... passed
  Testing mutant lib:5 ... failed
  Testing mutant lib:6 ... failed
  Testing mutant lib:7 ... failed
  Testing mutant lib:8 ... passed
  Writing report data to mutaml-report.json

  $ mutaml-report
  Attempting to read from mutaml-report.json...
  
  Mutaml report summary:
  ----------------------
  
   target                          #mutations      #failed      #timeouts      #passed 
   -------------------------------------------------------------------------------------
   lib.ml                                 9      77.8%    7     0.0%    0    22.2%    2
   =====================================================================================
  
  Mutation programs passing the test suite:
  -----------------------------------------
  
  Mutation "lib.ml-mutant4" passed (see "_mutations/lib.ml-mutant4.output"):
  
  --- lib.ml
  +++ lib.ml-mutant4
  @@ -21,7 +21,7 @@
   
   let pi total =
     let rec loop n inside =
  -    if n = 0 then
  +    if n = 1 then
         4. *. (float_of_int inside /. float_of_int total)
       else
         let x = 1.0 -. Random.float 2.0 in
  
  ---------------------------------------------------------------------------
  
  Mutation "lib.ml-mutant8" passed (see "_mutations/lib.ml-mutant8.output"):
  
  --- lib.ml
  +++ lib.ml-mutant8
  @@ -30,4 +30,4 @@
         then loop (n-1) (inside+1)
         else loop (n-1) (inside)
     in
  -  loop total 0
  +  loop total 1
  
  ---------------------------------------------------------------------------
  
Similar, but by passing a command line option:

  $ dune clean
  $ dune build ./ounittest.exe
  Running mutaml instrumentation on "lib.ml"
  Randomness seed: 896745231   Mutation rate: 50   GADTs enabled: true
  Created 9 mutations of lib.ml
  Writing mutation info to lib.muts

  $ ls _build/mutation
  lib.a
  lib.cmxa
  lib.ml
  lib.muts
  lib.pp.ml
  mutaml-mut-files.txt
  ounittest.exe
  ounittest.ml

  $ unset MUTAML_BUILD_CONTEXT
  $ mutaml-runner -build-context "_build/mutation" _build/mutation/ounittest.exe
  read mut file lib.muts
  Testing mutant lib:0 ... failed
  Testing mutant lib:1 ... failed
  Testing mutant lib:2 ... failed
  Testing mutant lib:3 ... failed
  Testing mutant lib:4 ... passed
  Testing mutant lib:5 ... failed
  Testing mutant lib:6 ... failed
  Testing mutant lib:7 ... failed
  Testing mutant lib:8 ... passed
  Writing report data to mutaml-report.json

  $ mutaml-report
  Attempting to read from mutaml-report.json...
  
  Mutaml report summary:
  ----------------------
  
   target                          #mutations      #failed      #timeouts      #passed 
   -------------------------------------------------------------------------------------
   lib.ml                                 9      77.8%    7     0.0%    0    22.2%    2
   =====================================================================================
  
  Mutation programs passing the test suite:
  -----------------------------------------
  
  Mutation "lib.ml-mutant4" passed (see "_mutations/lib.ml-mutant4.output"):
  
  --- lib.ml
  +++ lib.ml-mutant4
  @@ -21,7 +21,7 @@
   
   let pi total =
     let rec loop n inside =
  -    if n = 0 then
  +    if n = 1 then
         4. *. (float_of_int inside /. float_of_int total)
       else
         let x = 1.0 -. Random.float 2.0 in
  
  ---------------------------------------------------------------------------
  
  Mutation "lib.ml-mutant8" passed (see "_mutations/lib.ml-mutant8.output"):
  
  --- lib.ml
  +++ lib.ml-mutant8
  @@ -30,4 +30,4 @@
         then loop (n-1) (inside+1)
         else loop (n-1) (inside)
     in
  -  loop total 0
  +  loop total 1
  
  ---------------------------------------------------------------------------
  
Finally, test overriding:

Similar, but by passing a command line option:

  $ dune clean
  $ dune build ./ounittest.exe
  Running mutaml instrumentation on "lib.ml"
  Randomness seed: 896745231   Mutation rate: 50   GADTs enabled: true
  Created 9 mutations of lib.ml
  Writing mutation info to lib.muts

  $ ls _build/mutation
  lib.a
  lib.cmxa
  lib.ml
  lib.muts
  lib.pp.ml
  mutaml-mut-files.txt
  ounittest.exe
  ounittest.ml

  $ export MUTAML_BUILD_CONTEXT="_build/in-a-galaxy-far-far-away"
  $ mutaml-runner -build-context "_build/mutation" _build/mutation/ounittest.exe
  read mut file lib.muts
  Testing mutant lib:0 ... failed
  Testing mutant lib:1 ... failed
  Testing mutant lib:2 ... failed
  Testing mutant lib:3 ... failed
  Testing mutant lib:4 ... passed
  Testing mutant lib:5 ... failed
  Testing mutant lib:6 ... failed
  Testing mutant lib:7 ... failed
  Testing mutant lib:8 ... passed
  Writing report data to mutaml-report.json

  $ mutaml-report
  Attempting to read from mutaml-report.json...
  
  Mutaml report summary:
  ----------------------
  
   target                          #mutations      #failed      #timeouts      #passed 
   -------------------------------------------------------------------------------------
   lib.ml                                 9      77.8%    7     0.0%    0    22.2%    2
   =====================================================================================
  
  Mutation programs passing the test suite:
  -----------------------------------------
  
  Mutation "lib.ml-mutant4" passed (see "_mutations/lib.ml-mutant4.output"):
  
  --- lib.ml
  +++ lib.ml-mutant4
  @@ -21,7 +21,7 @@
   
   let pi total =
     let rec loop n inside =
  -    if n = 0 then
  +    if n = 1 then
         4. *. (float_of_int inside /. float_of_int total)
       else
         let x = 1.0 -. Random.float 2.0 in
  
  ---------------------------------------------------------------------------
  
  Mutation "lib.ml-mutant8" passed (see "_mutations/lib.ml-mutant8.output"):
  
  --- lib.ml
  +++ lib.ml-mutant8
  @@ -30,4 +30,4 @@
         then loop (n-1) (inside+1)
         else loop (n-1) (inside)
     in
  -  loop total 0
  +  loop total 1
  
  ---------------------------------------------------------------------------
  



Here's an example of a manual diff from the console:

  $ diff -u --label "lib.ml" -u lib.ml --label "lib.ml-mutant6" _mutations/lib.ml-mutant6
  --- lib.ml
  +++ lib.ml-mutant6
  @@ -21,7 +21,7 @@
   
   let pi total =
     let rec loop n inside =
  -    if n = 0 then
  +    if n = 1 then
         4. *. (float_of_int inside /. float_of_int total)
       else
         let x = 1.0 -. Random.float 2.0 in
  [1]


Old git diff attempts
% $ git diff --no-index -U lib.ml lib.ml-mutant8
% $ git diff -D --no-index -- lib.ml lib.ml-mutant8
% $ git --no-pager diff --no-index --color=always -u --ignore-cr-at-eol lib.ml lib.ml-mutant8
% $ git diff --find-copies-harder -B -C -u --no-index lib.ml lib.ml-mutant8
