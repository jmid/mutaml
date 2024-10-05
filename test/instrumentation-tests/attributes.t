Create dune and dune-project files:
#  $ bash ../write_dune_files.sh

Create a dune-project file:
  $ echo "(lang dune 2.9)" > dune-project

Create a dune file enabling warnings

---------------------------------------------------

  $ cat > dune <<'EOF'
  > ;;(env (_ (flags (:standard -w +3))))  ;;all warnings
  > (executable
  >  (name test)
  >  ;;(flags (:standard <my options>))
  >  ;;(flags (:standard -w +3))
  >  (ocamlc_flags -dsource)
  >  (modes byte)
  >  (instrumentation (backend mutaml))
  > )
  > EOF


Create a test.ml file with an attribute
  $ cat > test.ml <<'EOF'
  > let greet () = print_endline ("Hello," ^ " world!")[@@ppwarning "Stop using hello world!"]
  > let () = greet()
  > EOF


Set seed and (full) mutation rate as environment variables, for repeatability
  $ export MUTAML_SEED=896745231
  $ export MUTAML_MUT_RATE=100


Preprocess, check for attribute and error
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml 2>&1 > output.txt
  $ head -n 4 output.txt && echo "ERROR MESSAGE" && tail -n 12 output.txt
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts
  ERROR MESSAGE
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let __is_mutaml_mutant__ m =
    match __MUTAML_MUTANT__ with
    | None -> false
    | Some mutant -> String.equal m mutant
  let greet () = print_endline ("Hello," ^ " world!")[@@ppwarning
                                                       "Stop using hello world!"]
  let () = greet ()
  File "test.ml", line 1, characters 64-89:
  1 | let greet () = print_endline ("Hello," ^ " world!")[@@ppwarning "Stop using hello world!"]
                                                                      ^^^^^^^^^^^^^^^^^^^^^^^^^
  Error (warning 22 [preprocessor]): Stop using hello world!

--------------------------------------------------------------------------------

Try same example, but disabling warning 22 via the dune file:

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (ocamlc_flags -dsource -w -22)
  >  (modes byte)
  >  (instrumentation (backend mutaml))
  > )
  > EOF


Preprocess, check that attribute no longer triggers an error

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let __is_mutaml_mutant__ m =
    match __MUTAML_MUTANT__ with
    | None -> false
    | Some mutant -> String.equal m mutant
  let greet () = print_endline ("Hello," ^ " world!")[@@ppwarning
                                                       "Stop using hello world!"]
  let () = greet ()

--------------------------------------------------------------------------------

Another example with '@deprecated':

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (ocamlc_flags -dsource -alert +deprecated)
  >  (modes byte)
  >  (instrumentation (backend mutaml))
  > )
  > EOF


Create a test.ml file with a module attribute
  $ cat > test.ml <<'EOF'
  > module T : sig
  >              val greet : unit -> unit [@@deprecated "Please stop using that example"]
  >            end =
  > struct
  >   let greet () = print_endline ("Hello," ^ " world!")
  > end
  > let () = T.greet()
  > EOF

Preprocess, check that attribute triggers deprecation error

  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml 2>&1 > output.txt
  $ head -n 4 output.txt && echo "ERROR MESSAGE" && tail -n 14 output.txt
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts
  ERROR MESSAGE
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let __is_mutaml_mutant__ m =
    match __MUTAML_MUTANT__ with
    | None -> false
    | Some mutant -> String.equal m mutant
  module T :
    sig val greet : unit -> unit[@@deprecated "Please stop using that example"]
    end = struct let greet () = print_endline ("Hello," ^ " world!") end 
  let () = T.greet ()
  File "test.ml", line 7, characters 9-16:
  7 | let () = T.greet()
               ^^^^^^^
  Error (alert deprecated): T.greet
  Please stop using that example


--------------------------------------------------------------------------------

  $ cat > dune <<'EOF'
  > (executable
  >  (name test)
  >  (ocamlc_flags -dsource)
  >  (modes byte)
  >  (instrumentation (backend mutaml))
  > )
  > EOF



Attribute on a unit:
--------------------------------------------------------------------------------

Create a test.ml file with an attribute
  $ cat > test.ml <<'EOF'
  > let v = ()[@testattr "unit attr"]
  > EOF

Preprocess, check for attribute and error
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let __is_mutaml_mutant__ m =
    match __MUTAML_MUTANT__ with
    | None -> false
    | Some mutant -> String.equal m mutant
  let v = ((())[@testattr "unit attr"])


Attribute on a bool:
--------------------------------------------------------------------------------

Create a test.ml file with an attribute
  $ cat > test.ml <<'EOF'
  > let t = true[@testattr "true attr"]
  > let f = false[@testattr "false attr"]
  > EOF

Preprocess, check for attribute and error
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 2 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let __is_mutaml_mutant__ m =
    match __MUTAML_MUTANT__ with
    | None -> false
    | Some mutant -> String.equal m mutant
  let t =
    if __is_mutaml_mutant__ "test:0"
    then ((false)[@testattr "true attr"])
    else ((true)[@testattr "true attr"])
  let f =
    if __is_mutaml_mutant__ "test:1"
    then ((true)[@testattr "false attr"])
    else ((false)[@testattr "false attr"])


Attribute on a string:
--------------------------------------------------------------------------------

Create a test.ml file with an attribute
  $ cat > test.ml <<'EOF'
  > let str = " "[@testattr "str attr"]
  > EOF

Preprocess, check for attribute and error
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let __is_mutaml_mutant__ m =
    match __MUTAML_MUTANT__ with
    | None -> false
    | Some mutant -> String.equal m mutant
  let str =
    if __is_mutaml_mutant__ "test:0"
    then (("")[@testattr "str attr"])
    else ((" ")[@testattr "str attr"])


Attribute on an arithmetic expression:
--------------------------------------------------------------------------------

Create a test.ml file with an attribute
  $ cat > test.ml <<'EOF'
  > let f x = (x + 1)[@testattr "str attr"]
  > EOF

Preprocess, check for attribute and error
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 1 mutation of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  let __is_mutaml_mutant__ m =
    match __MUTAML_MUTANT__ with
    | None -> false
    | Some mutant -> String.equal m mutant
  let f x =
    if __is_mutaml_mutant__ "test:0"
    then ((x)[@testattr "str attr"])
    else ((x + 1)[@testattr "str attr"])





3 forms of attributes:
@attr   - for expr,typexpr,pattern,module-expr,...,labels,constr
@@attr  - for "blocks": module-items, ...
@@@attr - for stand-alone/floating attributes

Some built-in ones:
[@@ppwarning]
[@@deprecated]
[@@alert]
[@tailcall]
[@@@warning "+9"] disable warning locally
[@@inline]
[@@inlined]
