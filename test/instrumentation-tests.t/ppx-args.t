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

  $ dune build ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 50   GADTs enabled: false
  Created 1 mutation of test.ml
  Writing mutation info to test.muts


Try passing another seed value:

  $ dune clean
  $ export MUTAML_SEED=4231

  $ dune build ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 4231   Mutation rate: 50   GADTs enabled: false
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

  $ dune build ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 50   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts

-----------------------------------------------------------------------
Create a dune file passing only -gadt
Instrument and check that it was received
-----------------------------------------------------------------------

  $ dune clean
  $ unset MUTAML_GADT

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (modes byte)
  >  (instrumentation (backend mutaml -gadt))
  > )
  > EOF

  $ dune build ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 50   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts

-----------------------------------------------------------------------
Same dune file passing a seed + environment variable seed
Here the dune file parameter should take precedence
-----------------------------------------------------------------------

Force dune to rebuild
  $ dune clean

  $ export MUTAML_GADT=false

  $ dune build ./test.bc --force --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 50   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts




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

  $ dune build ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 42   Mutation rate: 50   GADTs enabled: false
  Created 0 mutations of test.ml
  Writing mutation info to test.muts

-----------------------------------------------------------------------
Same dune file passing a seed + environment variable seed
Here the dune file parameter should take precedence
-----------------------------------------------------------------------

Force dune to rebuild
  $ dune clean

  $ export MUTAML_SEED=896745231

  $ dune build ./test.bc --force --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 42   Mutation rate: 50   GADTs enabled: false
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

  $ dune build ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: false
  Created 1 mutation of test.ml
  Writing mutation info to test.muts

Try with another value - 33:

  $ dune clean
  $ export MUTAML_MUT_RATE=33
  $ dune build ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 33   GADTs enabled: false
  Created 0 mutations of test.ml
  Writing mutation info to test.muts

Try with another value - 0:

  $ dune clean
  $ export MUTAML_MUT_RATE=0
  $ dune build ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 0   GADTs enabled: false
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

  $ dune build ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 75   GADTs enabled: false
  Created 1 mutation of test.ml
  Writing mutation info to test.muts

-----------------------------------------------------------------------
Same dune file passing mut-rate + environment variable mut-rate
Here the dune file parameter should take precedence
-----------------------------------------------------------------------

  $ dune clean

  $ export MUTAML_MUT_RATE=100

  $ dune build ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 75   GADTs enabled: false
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


  $ dune build ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 42   Mutation rate: 75   GADTs enabled: false
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

  $ dune build ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 0   GADTs enabled: false
  Created 0 mutations of test.ml
  Writing mutation info to test.muts


Repeat with a few other seeds:

  $ dune clean
  $ export MUTAML_SEED=325
  $ dune build ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 325   Mutation rate: 0   GADTs enabled: false
  Created 0 mutations of test.ml
  Writing mutation info to test.muts


  $ dune clean
  $ export MUTAML_SEED=87324
  $ dune build ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 87324   Mutation rate: 0   GADTs enabled: false
  Created 0 mutations of test.ml
  Writing mutation info to test.muts


  $ dune clean
  $ export MUTAML_SEED=9825453
  $ dune build ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 9825453   Mutation rate: 0   GADTs enabled: false
  Created 0 mutations of test.ml
  Writing mutation info to test.muts
