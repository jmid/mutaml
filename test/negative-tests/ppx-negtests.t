Create a test.ml file with a few prints:
  $ cat > test.ml <<'EOF'
  > let () = print_int 10
  > let () = print_newline()
  > EOF

Create a dune-project file:
  $ echo "(lang dune 2.9)" > dune-project

-----------------------------------------------------------------------
Test invalid environment variables
-----------------------------------------------------------------------

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (modes byte)
  >  (instrumentation (backend mutaml))
  > )
  > EOF

  $ export MUTAML_GADT=sometimes
  $ dune build ./test.bc --instrument-with mutaml 2>&1 | head | sed -e 's/ppx\/[^\/]*\/ppx\.exe/ppx\/path\/ppx\.exe/g'
           ppx test.pp.ml (exit 1)
  (cd _build/default && .ppx/path/ppx.exe -o test.pp.ml --impl test.ml -corrected-suffix .ppx-corrected -diff-cmd - -dump-ast)
  Invalid gadt string: sometimes


  $ dune clean
  $ unset MUTAML_GADT
  $ export MUTAML_SEED=-4611686018427387905
  $ dune build ./test.bc --instrument-with mutaml 2>&1 | head | sed -e 's/ppx\/[^\/]*\/ppx\.exe/ppx\/path\/ppx\.exe/g'
           ppx test.pp.ml (exit 1)
  (cd _build/default && .ppx/path/ppx.exe -o test.pp.ml --impl test.ml -corrected-suffix .ppx-corrected -diff-cmd - -dump-ast)
  Invalid randomness seed: -4611686018427387905


  $ dune clean
  $ export MUTAML_SEED=4611686018427387904
  $ dune build ./test.bc --instrument-with mutaml 2>&1 | head | sed -e 's/ppx\/[^\/]*\/ppx\.exe/ppx\/path\/ppx\.exe/g'
           ppx test.pp.ml (exit 1)
  (cd _build/default && .ppx/path/ppx.exe -o test.pp.ml --impl test.ml -corrected-suffix .ppx-corrected -diff-cmd - -dump-ast)
  Invalid randomness seed: 4611686018427387904


  $ dune clean
  $ export MUTAML_SEED=12likeREEEAALLLYrandom34
  $ dune build ./test.bc --instrument-with mutaml 2>&1 | head | sed -e 's/ppx\/[^\/]*\/ppx\.exe/ppx\/path\/ppx\.exe/g'
           ppx test.pp.ml (exit 1)
  (cd _build/default && .ppx/path/ppx.exe -o test.pp.ml --impl test.ml -corrected-suffix .ppx-corrected -diff-cmd - -dump-ast)
  Invalid randomness seed: 12likeREEEAALLLYrandom34


  $ dune clean
  $ unset MUTAML_SEED
  $ export MUTAML_MUT_RATE=110
  $ dune build ./test.bc --instrument-with mutaml 2>&1 | head | sed -e 's/ppx\/[^\/]*\/ppx\.exe/ppx\/path\/ppx\.exe/g'
           ppx test.pp.ml (exit 1)
  (cd _build/default && .ppx/path/ppx.exe -o test.pp.ml --impl test.ml -corrected-suffix .ppx-corrected -diff-cmd - -dump-ast)
  Invalid mutation rate: 110


  $ dune clean
  $ export MUTAML_MUT_RATE=-10
  $ dune build ./test.bc --instrument-with mutaml 2>&1 | head | sed -e 's/ppx\/[^\/]*\/ppx\.exe/ppx\/path\/ppx\.exe/g'
           ppx test.pp.ml (exit 1)
  (cd _build/default && .ppx/path/ppx.exe -o test.pp.ml --impl test.ml -corrected-suffix .ppx-corrected -diff-cmd - -dump-ast)
  Invalid mutation rate: -10


  $ dune clean
  $ export MUTAML_MUT_RATE=always
  $ dune build ./test.bc --instrument-with mutaml 2>&1 | head | sed -e 's/ppx\/[^\/]*\/ppx\.exe/ppx\/path\/ppx\.exe/g'
           ppx test.pp.ml (exit 1)
  (cd _build/default && .ppx/path/ppx.exe -o test.pp.ml --impl test.ml -corrected-suffix .ppx-corrected -diff-cmd - -dump-ast)
  Invalid mutation rate: always


  $ unset MUTAML_MUT_RATE

-----------------------------------------------------------------------
Create a dune file passing an invalid mutation rate
Instrument and check that it is rejected
-----------------------------------------------------------------------

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (modes byte)
  >  (instrumentation (backend mutaml -mut-rate 110))
  > )
  > EOF

  $ dune build ./test.bc --instrument-with mutaml 2>&1 | head | sed -e 's/ppx\/[^\/]*\/ppx\.exe/ppx\/path\/ppx\.exe/g'
           ppx test.pp.ml (exit 2)
  (cd _build/default && .ppx/path/ppx.exe -mut-rate 110 -o test.pp.ml --impl test.ml -corrected-suffix .ppx-corrected -diff-cmd - -dump-ast)
  .ppx/path/ppx.exe: Invalid mutation rate: 110.
  ppx.exe [extra_args] [<files>]
    -as-ppx                     Run as a -ppx rewriter (must be the first argument)
    --as-ppx                    Same as -as-ppx
    -as-pp                      Shorthand for: -dump-ast -embed-errors
    --as-pp                     Same as -as-pp
    -o <filename>               Output file (use '-' for stdout)
    -                           Read input from stdin


-----------------------------------------------------------------------
Create a dune file passing an negative mutation rate
Instrument and check that it is rejected
-----------------------------------------------------------------------

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (modes byte)
  >  (instrumentation (backend mutaml -mut-rate -10))
  > )
  > EOF

  $ dune build ./test.bc --instrument-with mutaml 2>&1 | head | sed -e 's/ppx\/[^\/]*\/ppx\.exe/ppx\/path\/ppx\.exe/g'
           ppx test.pp.ml (exit 2)
  (cd _build/default && .ppx/path/ppx.exe -mut-rate -10 -o test.pp.ml --impl test.ml -corrected-suffix .ppx-corrected -diff-cmd - -dump-ast)
  .ppx/path/ppx.exe: Invalid mutation rate: -10.
  ppx.exe [extra_args] [<files>]
    -as-ppx                     Run as a -ppx rewriter (must be the first argument)
    --as-ppx                    Same as -as-ppx
    -as-pp                      Shorthand for: -dump-ast -embed-errors
    --as-pp                     Same as -as-pp
    -o <filename>               Output file (use '-' for stdout)
    -                           Read input from stdin


-----------------------------------------------------------------------
Create a dune file passing an invalid mutation rate
Instrument and check that it is rejected
-----------------------------------------------------------------------

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (modes byte)
  >  (instrumentation (backend mutaml -mut-rate eeeEEEEEXTREMELYHIGH))
  > )
  > EOF

  $ dune build ./test.bc --instrument-with mutaml 2>&1 | head | sed -e 's/ppx\/[^\/]*\/ppx\.exe/ppx\/path\/ppx\.exe/g'
           ppx test.pp.ml (exit 2)
  (cd _build/default && .ppx/path/ppx.exe -mut-rate eeeEEEEEXTREMELYHIGH -o test.pp.ml --impl test.ml -corrected-suffix .ppx-corrected -diff-cmd - -dump-ast)
  .ppx/path/ppx.exe: wrong argument 'eeeEEEEEXTREMELYHIGH'; option '-mut-rate' expects an integer.
  ppx.exe [extra_args] [<files>]
    -as-ppx                     Run as a -ppx rewriter (must be the first argument)
    --as-ppx                    Same as -as-ppx
    -as-pp                      Shorthand for: -dump-ast -embed-errors
    --as-pp                     Same as -as-pp
    -o <filename>               Output file (use '-' for stdout)
    -                           Read input from stdin


-----------------------------------------------------------------------
Create a dune file passing an invalid seed (max_int + 1)
Instrument and check that it is rejected
-----------------------------------------------------------------------

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (modes byte)
  >  (instrumentation (backend mutaml -seed 4611686018427387904))
  > )
  > EOF

  $ dune build ./test.bc --instrument-with mutaml 2>&1 | head | sed -e 's/ppx\/[^\/]*\/ppx\.exe/ppx\/path\/ppx\.exe/g'
           ppx test.pp.ml (exit 2)
  (cd _build/default && .ppx/path/ppx.exe -seed 4611686018427387904 -o test.pp.ml --impl test.ml -corrected-suffix .ppx-corrected -diff-cmd - -dump-ast)
  .ppx/path/ppx.exe: wrong argument '4611686018427387904'; option '-seed' expects an integer.
  ppx.exe [extra_args] [<files>]
    -as-ppx                     Run as a -ppx rewriter (must be the first argument)
    --as-ppx                    Same as -as-ppx
    -as-pp                      Shorthand for: -dump-ast -embed-errors
    --as-pp                     Same as -as-pp
    -o <filename>               Output file (use '-' for stdout)
    -                           Read input from stdin


-----------------------------------------------------------------------
Create a dune file passing an invalid seed
Instrument and check that it is rejected
-----------------------------------------------------------------------

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (modes byte)
  >  (instrumentation (backend mutaml -seed 324random345))
  > )
  > EOF

  $ dune build ./test.bc --instrument-with mutaml 2>&1 | head | sed -e 's/ppx\/[^\/]*\/ppx\.exe/ppx\/path\/ppx\.exe/g'
           ppx test.pp.ml (exit 2)
  (cd _build/default && .ppx/path/ppx.exe -seed 324random345 -o test.pp.ml --impl test.ml -corrected-suffix .ppx-corrected -diff-cmd - -dump-ast)
  .ppx/path/ppx.exe: wrong argument '324random345'; option '-seed' expects an integer.
  ppx.exe [extra_args] [<files>]
    -as-ppx                     Run as a -ppx rewriter (must be the first argument)
    --as-ppx                    Same as -as-ppx
    -as-pp                      Shorthand for: -dump-ast -embed-errors
    --as-pp                     Same as -as-pp
    -o <filename>               Output file (use '-' for stdout)
    -                           Read input from stdin


-----------------------------------------------------------------------
Create a dune file passing --help
Instrument and check that it was received
-----------------------------------------------------------------------

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (modes byte)
  >  (instrumentation (backend mutaml --help))
  > )
  > EOF

  $ dune build ./test.bc --instrument-with mutaml
           ppx test.pp.ml
  ppx.exe [extra_args] [<files>]
    -as-ppx                     Run as a -ppx rewriter (must be the first argument)
    --as-ppx                    Same as -as-ppx
    -as-pp                      Shorthand for: -dump-ast -embed-errors
    --as-pp                     Same as -as-pp
    -o <filename>               Output file (use '-' for stdout)
    -                           Read input from stdin
    -dump-ast                   Dump the marshaled ast to the output file instead of pretty-printing it
    --dump-ast                  Same as -dump-ast
    -dparsetree                 Print the parsetree (same as ocamlc -dparsetree)
    -embed-errors               Embed errors in the output AST (default: true when -dump-ast, false otherwise)
    -null                       Produce no output, except for errors
    -impl <file>                Treat the input as a .ml file
    --impl <file>               Same as -impl
    -intf <file>                Treat the input as a .mli file
    --intf <file>               Same as -intf
    -debug-attribute-drop       Debug attribute dropping
    -print-transformations      Print linked-in code transformations, in the order they are applied
    -print-passes               Print the actual passes over the whole AST in the order they are applied
    -ite-check                  (no effect -- kept for compatibility)
    -pp <command>               Pipe sources through preprocessor <command> (incompatible with -as-ppx)
    -reconcile                  (WIP) Pretty print the output using a mix of the input source and the generated code
    -reconcile-with-comments    (WIP) same as -reconcile but uses comments to enclose the generated code
    -no-color                   Don't use colors when printing errors
    -diff-cmd                   Diff command when using code expectations (use - to disable diffing)
    -pretty                     Instruct code generators to improve the prettiness of the generated code
    -styler                     Code styler
    -output-metadata FILE       Where to store the output metadata
    -corrected-suffix SUFFIX    Suffix to append to corrected files
    -loc-filename <string>      File name to use in locations
    -reserve-namespace <string> Mark the given namespace as reserved
    -no-check                   Disable checks (unsafe)
    -check                      Enable checks
    -no-check-on-extensions     Disable checks on extension point only
    -check-on-extensions        Enable checks on extension point only
    -no-locations-check         Disable locations check only
    -locations-check            Enable locations check only
    -apply <names>              Apply these transformations in order (comma-separated list)
    -dont-apply <names>         Exclude these transformations
    -no-merge                   Do not merge context free transformations (better for debugging rewriters)
    -cookie NAME=EXPR           Set the cookie NAME to EXPR
    --cookie                    Same as -cookie
    -seed                       Set randomness seed for mutaml's instrumentation
    -mut-rate                   Set probability in % of mutating a syntax tree node (default: 50%)
    -gadt                       Only allow pattern mutations compatible GADTs (default: off)
    -help                       Display this list of options
    --help                      Display this list of options
  File "dune", line 4, characters 1-42:
  4 |  (instrumentation (backend mutaml --help))
       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  Error: Rule failed to generate the following targets:
  - test.pp.ml
  [1]
