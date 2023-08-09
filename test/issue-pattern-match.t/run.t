Let us try something:

  $ ls ../filter_dune_build.sh
  ../filter_dune_build.sh

Create a file with a 'when' clause reduced from https://github.com/jmid/mutaml/issues/22
  $ cat > test.ml << EOF
  > let accepted_codes n = (n=42)
  > let make status =
  >   let open Unix in
  >   let exit_status = match status with
  >     | WEXITED n when accepted_codes n -> Ok n
  >     | WEXITED n -> Error (Printf.sprintf "Exited %n" n)
  >     | WSIGNALED n -> Error (Printf.sprintf "Signaled %n" n)
  >     | WSTOPPED _ -> assert false
  >   in
  >   exit_status
  > ;;
  > assert (make (Unix.WEXITED 0) = Error "Exited 0")
  > EOF

Create the dune files:
  $ cat > dune-project << EOF
  > (lang dune 2.9)
  > EOF

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (ocamlc_flags -dsource)
  >  (libraries unix)
  >  (instrumentation (backend mutaml))
  > )
  > EOF

Check that files were created as expected:
  $ ls dune* test.ml
  dune
  dune-project
  test.ml

Set seed and (full) mutation rate as environment variables, for repeatability
  $ export MUTAML_SEED=896745231
  $ export MUTAML_MUT_RATE=100

  $ ../filter_dune_build.sh ./test.exe --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 2 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let accepted_codes n =
    n = (if __MUTAML_MUTANT__ = (Some "test:0") then 43 else 42)
  let make status =
    let open Unix in
      let exit_status =
        ((match status with
          | WEXITED n when
              (accepted_codes n) && (__MUTAML_MUTANT__ <> (Some "test:1")) ->
              Ok n
          | WEXITED n -> Error (Printf.sprintf "Exited %n" n)
          | WSIGNALED n -> Error (Printf.sprintf "Signaled %n" n)
          | WSTOPPED _ -> assert false)
        [@ocaml.warning "-8"]) in
      exit_status
  ;;assert ((make (Unix.WEXITED 0)) = (Error "Exited 0"))

  $ ls _build
  default
  log

  $ ls _build/default
  mutaml-mut-files.txt
  test.exe
  test.ml
  test.muts
  test.pp.ml

  $ mutaml-runner _build/default/test.exe
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
  @@ -1,4 +1,4 @@
  -let accepted_codes n = (n=42)
  +let accepted_codes n = (n=43)
   let make status =
     let open Unix in
     let exit_status = match status with
  
  ---------------------------------------------------------------------------
  
  Mutation "test.ml-mutant1" passed (see "_mutations/test.ml-mutant1.output"):
  
  --- test.ml
  +++ test.ml-mutant1
  @@ -2,7 +2,6 @@
   let make status =
     let open Unix in
     let exit_status = match status with
  -    | WEXITED n when accepted_codes n -> Ok n
       | WEXITED n -> Error (Printf.sprintf "Exited %n" n)
       | WSIGNALED n -> Error (Printf.sprintf "Signaled %n" n)
       | WSTOPPED _ -> assert false
  
  ---------------------------------------------------------------------------
  




  $ ls _mutations
  test.ml-mutant0
  test.ml-mutant1
  test.muts-mutant0.output
  test.muts-mutant1.output
