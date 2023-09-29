Create a test.ml file with a few prints:
  $ cat > test.ml <<'EOF'
  > let () = print_int 10
  > let () = print_newline()
  > EOF

Create a dune-project file:
  $ echo "(lang dune 2.9)" > dune-project


-----------------------------------------------------------------------
Test default behaviour when passing only seed as environment variable
-----------------------------------------------------------------------

  $ export MUTAML_SEED=896745231

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (modes byte)
  >  (instrumentation (backend mutaml))
  > )
  > EOF

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 50   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts


Try passing another seed value:

  $ dune clean
  $ export MUTAML_SEED=4231

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 4231   Mutation rate: 50   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts


-----------------------------------------------------------------------
Test the different options for passing gadt:
 * pass as environment variable
 * pass as parameter in dune file
 * pass as both environment variable and as parameter in dune file
 * no passing (above)
-----------------------------------------------------------------------

-----------------------------------------------------------------------
Create a dune file without passing gadt option. Pass it as env.var.
Instrument and check that it was received
-----------------------------------------------------------------------

  $ dune clean
  $ export MUTAML_SEED=896745231
  $ export MUTAML_GADT=true

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (modes byte)
  >  (instrumentation (backend mutaml))
  > )
  > EOF

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 50   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts

-----------------------------------------------------------------------
Create a dune file passing only -gadt true
Instrument and check that it was received
-----------------------------------------------------------------------

  $ dune clean
  $ unset MUTAML_GADT

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (modes byte)
  >  (instrumentation (backend mutaml -gadt true))
  > )
  > EOF

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 50   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts


-----------------------------------------------------------------------
Create a dune file passing only -gadt false
Instrument and check that it was received
-----------------------------------------------------------------------

  $ dune clean
  $ unset MUTAML_GADT

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (modes byte)
  >  (instrumentation (backend mutaml -gadt false))
  > )
  > EOF

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 50   GADTs enabled: false
  Created 1 mutation of test.ml
  Writing mutation info to test.muts


-----------------------------------------------------------------------
Same dune file passing a seed + environment variable seed
Here the dune file parameter should take precedence
-----------------------------------------------------------------------

Force dune to rebuild
  $ dune clean

  $ export MUTAML_GADT=false

  $ bash ../filter_dune_build.sh ./test.bc --force --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 50   GADTs enabled: false
  Created 1 mutation of test.ml
  Writing mutation info to test.muts

  $ unset MUTAML_GADT



-----------------------------------------------------------------------
Test the different options for passing a seed:
 * pass as environment variable (above)
 * pass as parameter in dune file
 * pass as both environment variable and as parameter in dune file
 * no passing (omitted because of non-determinism)
-----------------------------------------------------------------------

-----------------------------------------------------------------------
Create a dune file passing only seed
Instrument and check that it was received
-----------------------------------------------------------------------

  $ unset MUTAML_SEED

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (modes byte)
  >  (instrumentation (backend mutaml -seed 42))
  > )
  > EOF

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 42   Mutation rate: 50   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts

-----------------------------------------------------------------------
Same dune file passing a seed + environment variable seed
Here the dune file parameter should take precedence
-----------------------------------------------------------------------

Force dune to rebuild
  $ dune clean

  $ export MUTAML_SEED=896745231

  $ bash ../filter_dune_build.sh ./test.bc --force --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 42   Mutation rate: 50   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts



-----------------------------------------------------------------------
Test the different options for passing mutation rate:
 * pass as environment variable
 * pass as parameter in dune file
 * pass as both environment variable and as parameter in dune file
 * no passing (above)
-----------------------------------------------------------------------

-----------------------------------------------------------------------
Create a dune file without passing mut-rate. Pass it as env.var.
Instrument and check that it was received
-----------------------------------------------------------------------

  $ export MUTAML_MUT_RATE=100

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (modes byte)
  >  (instrumentation (backend mutaml))
  > )
  > EOF

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts

Try with another value - 33:

  $ dune clean
  $ export MUTAML_MUT_RATE=33
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 33   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts

Try with another value - 0:

  $ dune clean
  $ export MUTAML_MUT_RATE=0
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 0   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts


-----------------------------------------------------------------------
Create a dune file passing only mut-rate
Instrument and check that it was received
-----------------------------------------------------------------------

  $ unset MUTAML_MUT_RATE

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (modes byte)
  >  (instrumentation (backend mutaml -mut-rate 75))
  > )
  > EOF

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 75   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts

-----------------------------------------------------------------------
Same dune file passing mut-rate + environment variable mut-rate
Here the dune file parameter should take precedence
-----------------------------------------------------------------------

  $ dune clean

  $ export MUTAML_MUT_RATE=100

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 75   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts


-----------------------------------------------------------------------
Create a dune file passing both seed and mut-rate
Instrument and check that they were received
-----------------------------------------------------------------------

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (modes byte)
  >  (instrumentation (backend mutaml -seed 42 -mut-rate 75))
  > )
  > EOF


  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 42   Mutation rate: 75   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts





-----------------------------------------------------------------------
Test no mutation - with mutation rate 0
-----------------------------------------------------------------------

Create a test.ml file with a few prints:
  $ cat > test.ml <<'EOF'
  > let l = [0;1;2;3;4;5;6;7;8;9]
  > let o = if false || true then " " else ""
  > let () = print_int 10
  > let () = print_newline()
  > EOF

-----------------------------------------------------------------------
Create a dune file passing mut-rate 0
Instrument and check that it was received - with no mutation
-----------------------------------------------------------------------

  $ unset MUTAML_MUT_RATE

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (modes byte)
  >  (instrumentation (backend mutaml -mut-rate 0))
  > )
  > EOF

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 0   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts


Repeat with a few other seeds:

  $ dune clean
  $ export MUTAML_SEED=325
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 325   Mutation rate: 0   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts


  $ dune clean
  $ export MUTAML_SEED=87324
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 87324   Mutation rate: 0   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts


  $ dune clean
  $ export MUTAML_SEED=9825453
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 9825453   Mutation rate: 0   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts

-----------------------------------------------------------------------
Test behaviour with another building context
-----------------------------------------------------------------------

Create a dune-workspace file with another build context:
  $ cat > dune-workspace <<'EOF'
  > (lang dune 2.9)
  > (context default)
  > (context (default (name mutation) (instrument_with mutaml)))
  > EOF

And a dune file:
  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (modes byte)
  >  (instrumentation (backend mutaml))
  > )
  > EOF



  $ dune clean
  $ export MUTAML_SEED=896745231
  $ bash ../filter_dune_build.sh _build/mutation/test.bc --force
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 50   GADTs enabled: true
  Created 7 mutations of test.ml
  Writing mutation info to test.muts


  $ ls _build/mutation
  mutaml-mut-files.txt
  test.bc
  test.ml
  test.muts
  test.pp.ml

  $ export MUTAML_BUILD_CONTEXT="_build/mutation"
  $ mutaml-runner _build/mutation/test.bc
  read mut file test.muts
  Testing mutant test:0 ... passed
  Testing mutant test:1 ... passed
  Testing mutant test:2 ... passed
  Testing mutant test:3 ... passed
  Testing mutant test:4 ... passed
  Testing mutant test:5 ... passed
  Testing mutant test:6 ... passed
  Writing report data to mutaml-report.json
