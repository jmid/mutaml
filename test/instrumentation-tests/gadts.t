Create dune and dune-project files:

  $ bash ../write_dune_files.sh


An example from Gabriel with GADTs (function-matching).
----------------------------------------------------------------------------

  $ cat > test.ml <<'EOF'
  > type _ t =
  >   | Int : int t
  >   | Bool : bool t
  > 
  > let f (type a) : a t -> a = function
  >   | Int -> 0
  >   | Bool -> true
  > 
  > let () = f Int |> Printf.printf "%i\n"
  > EOF


Check that the example typechecks
  $ ocamlc -stop-after typing test.ml
  $ export MUTAML_SEED=896745231
  $ export MUTAML_MUT_RATE=100
  $ export MUTAML_GADT=true
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 2 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type _ t =
    | Int: int t 
    | Bool: bool t 
  let f (type a) =
    (function
     | Int -> if __MUTAML_MUTANT__ = (Some "test:0") then 1 else 0
     | Bool -> if __MUTAML_MUTANT__ = (Some "test:1") then false else true : 
    a t -> a)
  let () = (f Int) |> (Printf.printf "%i\n")

This shouldn't fail. It should just fail to mutate the patterns.




Same example from Gabriel with GADTs ('match'-matching)
--------------------------------------------------------------------------------

  $ cat > test.ml <<'EOF'
  > type _ t =
  >   | Int : int t
  >   | Bool : bool t
  > 
  > let f (type a) : a t -> a = fun x -> match x with
  >   | Int -> 0
  >   | Bool -> true
  > 
  > let () = f Int |> Printf.printf "%i\n"
  > EOF

Check that the example typechecks
  $ ocamlc -stop-after typing test.ml
  $ export MUTAML_SEED=896745231
  $ export MUTAML_GADT=true
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 2 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type _ t =
    | Int: int t 
    | Bool: bool t 
  let f (type a) =
    (fun x ->
       match x with
       | Int -> if __MUTAML_MUTANT__ = (Some "test:0") then 1 else 0
       | Bool -> if __MUTAML_MUTANT__ = (Some "test:1") then false else true : 
    a t -> a)
  let () = (f Int) |> (Printf.printf "%i\n")

This shouldn't fail. It should just fail to mutate the patterns.




GADT example from the manual
--------------------------------------------------------------------------------

  $ cat > test.ml <<'EOF'
  > type _ t =
  >   | Int : int t
  >   | Bool : bool t
  > 
  > let deep : (char t * int) option -> char = function
  >  | None -> 'c'
  >  | _ -> .
  > EOF

Check that the example typechecks
  $ ocamlc -stop-after typing test.ml
  $ export MUTAML_SEED=896745231
  $ export MUTAML_GADT=true
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type _ t =
    | Int: int t 
    | Bool: bool t 
  let deep : (char t * int) option -> char = function | None -> 'c' | _ -> .

This shouldn't fail. It should just fail to mutate the patterns.





GADT example from manual w.match + an impossible case
--------------------------------------------------------------------------------

  $ cat > test.ml <<'EOF'
  > type _ t =
  >   | Int : int t
  >   | Bool : bool t
  > 
  > let deep_match : (char t * int) option -> char = fun x -> match x with
  >  | None -> 'c'
  >  | Some (_,0) -> .
  >  | _ -> .
  > EOF

Check that the example typechecks
  $ ocamlc -stop-after typing test.ml
  $ export MUTAML_SEED=896745231
  $ export MUTAML_GADT=true
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type _ t =
    | Int: int t 
    | Bool: bool t 
  let deep_match : (char t * int) option -> char =
    fun x -> match x with | None -> 'c' | Some (_, 0) -> . | _ -> .

This shouldn't fail. It should just fail to mutate the patterns.





GADT example from manual w.match
--------------------------------------------------------------------------------

  $ cat > test.ml <<'EOF'
  > type _ t =
  >   | Int : int t
  >   | Bool : bool t
  > 
  > let deep_match_refut : (char t * int) option -> char = fun x -> match x with
  >  | None -> 'c'
  >  (*| Some (_,0) -> .*)  (*impossible, type-wise*)
  >  | Some (_,_i) -> .  (*impossible, type-wise*)
  > EOF

Check that the example typechecks
  $ ocamlc -stop-after typing test.ml
  $ export MUTAML_SEED=896745231
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type _ t =
    | Int: int t 
    | Bool: bool t 
  let deep_match_refut : (char t * int) option -> char =
    fun x -> match x with | None -> 'c' | Some (_, _i) -> .


This shouldn't fail. It should just fail to mutate the patterns.





More GADT examples
--------------------------------------------------------------------------------

Pattern matching on GADT constructors in arrays:

  $ cat > test.ml <<'EOF'
  > type _ t =
  >   | Int : int t
  >   | Bool : bool t
  > 
  > let f (type a) : a t array -> a = function
  >  | [| Int ; Int |] -> 0
  >  | [| Bool |] -> true
  >  | _ -> failwith "ouch"
  > EOF

Check that the example typechecks
  $ ocamlc -stop-after typing test.ml
  $ export MUTAML_SEED=896745231
  $ export MUTAML_GADT=true
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 4 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type _ t =
    | Int: int t 
    | Bool: bool t 
  let f (type a) =
    (function
     | [|Int;Int|] when __MUTAML_MUTANT__ <> (Some "test:3") ->
         if __MUTAML_MUTANT__ = (Some "test:0") then 1 else 0
     | [|Bool|] when __MUTAML_MUTANT__ <> (Some "test:2") ->
         if __MUTAML_MUTANT__ = (Some "test:1") then false else true
     | _ -> failwith "ouch" : a t array -> a)



Pattern matching on GADT constructors in arrays:

  $ cat > test.ml <<'EOF'
  > type _ t =
  >   | Int : int t
  >   | Bool : bool t
  >   | Char : char t
  > 
  > let f (type a) : a t array -> a = function
  >  | [| Int  |] -> 0
  >  | [| Bool |] -> true
  >  | [| Char |] -> 'c'
  >  | _ when true (*2*2=2+2*) -> failwith "empty"
  >  | _ when false -> failwith "dead"
  > EOF

Check that the example typechecks
  $ ocamlc -stop-after typing test.ml
  File "test.ml", lines 6-11, characters 34-34:
   6 | ..................................function
   7 |  | [| Int  |] -> 0
   8 |  | [| Bool |] -> true
   9 |  | [| Char |] -> 'c'
  10 |  | _ when true (*2*2=2+2*) -> failwith "empty"
  11 |  | _ when false -> failwith "dead"
  Warning 8 [partial-match]: this pattern-matching is not exhaustive.
  Here is an example of a case that is not matched:
  [|  |]
  (However, some guarded clause may match this value.)
  $ export MUTAML_SEED=896745231
  $ export MUTAML_GADT=true
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml 2>&1 > output.txt
  $ head -n 4 output.txt && echo "ERROR MESSAGE" && tail -n 25 output.txt
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 4 mutations of test.ml
  Writing mutation info to test.muts
  ERROR MESSAGE
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type _ t =
    | Int: int t 
    | Bool: bool t 
    | Char: char t 
  let f (type a) =
    (function
     | [|Int|] -> if __MUTAML_MUTANT__ = (Some "test:0") then 1 else 0
     | [|Bool|] -> if __MUTAML_MUTANT__ = (Some "test:1") then false else true
     | [|Char|] -> 'c'
     | _ when if __MUTAML_MUTANT__ = (Some "test:2") then false else true ->
         failwith "empty"
     | _ when if __MUTAML_MUTANT__ = (Some "test:3") then true else false ->
         failwith "dead" : a t array -> a)
  File "test.ml", lines 6-11, characters 34-34:
   6 | ..................................function
   7 |  | [| Int  |] -> 0
   8 |  | [| Bool |] -> true
   9 |  | [| Char |] -> 'c'
  10 |  | _ when true (*2*2=2+2*) -> failwith "empty"
  11 |  | _ when false -> failwith "dead"
  Error (warning 8 [partial-match]): this pattern-matching is not exhaustive.
  Here is an example of a case that is not matched:
  [|  |]
  (However, some guarded clause may match this value.)




Pattern matching on GADT constructors in arrays w.variables:

  $ cat > test.ml <<'EOF'
  > type _ t =
  >   | Int : int t
  >   | Bool : bool t
  > let f (type a) : a t array -> a = function
  >  | [| _x ; Int |] -> 2
  >  | [| Bool ; _x |] -> true
  >  | _ -> failwith "eww";;
  > EOF

Check that the example typechecks
  $ ocamlc -stop-after typing test.ml
  $ export MUTAML_SEED=896745231
  $ export MUTAML_GADT=true
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 4 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type _ t =
    | Int: int t 
    | Bool: bool t 
  let f (type a) =
    (function
     | [|_x;Int|] when __MUTAML_MUTANT__ <> (Some "test:3") ->
         if __MUTAML_MUTANT__ = (Some "test:0") then 3 else 2
     | [|Bool;_x|] when __MUTAML_MUTANT__ <> (Some "test:2") ->
         if __MUTAML_MUTANT__ = (Some "test:1") then false else true
     | _ -> failwith "eww" : a t array -> a)




Pattern matching on GADT constructors in tuples, polymorphically:

  $ cat > test.ml <<'EOF'
  > type _ t =
  >   | Int : int t
  >   | Bool : bool t
  > 
  > let _f (type a) (type b) : (a t * b t) -> int = function | (Int,_) -> 0  | (_,Bool) -> 1 | _ -> 2
  > 
  > let _f (type a) (type b) : (a t * b t) -> int = function | (Int,Int) -> 0  | (Bool,Bool) -> 1 | _ -> 2
  > EOF

Check that the example typechecks
  $ ocamlc -stop-after typing test.ml
  $ export MUTAML_SEED=896745231
  $ export MUTAML_GADT=true
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 10 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type _ t =
    | Int: int t 
    | Bool: bool t 
  let _f (type a) (type b) =
    (function
     | (Int, _) when __MUTAML_MUTANT__ <> (Some "test:4") ->
         if __MUTAML_MUTANT__ = (Some "test:0") then 1 else 0
     | (_, Bool) when __MUTAML_MUTANT__ <> (Some "test:3") ->
         if __MUTAML_MUTANT__ = (Some "test:1") then 0 else 1
     | _ -> if __MUTAML_MUTANT__ = (Some "test:2") then 3 else 2 : (a t * b t)
                                                                     -> 
                                                                     int)
  let _f (type a) (type b) =
    (function
     | (Int, Int) when __MUTAML_MUTANT__ <> (Some "test:9") ->
         if __MUTAML_MUTANT__ = (Some "test:5") then 1 else 0
     | (Bool, Bool) when __MUTAML_MUTANT__ <> (Some "test:8") ->
         if __MUTAML_MUTANT__ = (Some "test:6") then 0 else 1
     | _ -> if __MUTAML_MUTANT__ = (Some "test:7") then 3 else 2 : (a t * b t)
                                                                     -> 
                                                                     int)



Pattern matching on GADT constructors in tuples, concretely:

  $ cat > test.ml <<'EOF'
  > type _ t =
  >   | Int : int t
  >   | Bool : bool t
  > 
  > let _f : (int t * bool t) -> int = function | (Int,_) -> 0  | (_,Bool) -> . | _ -> .
  > 
  > let _f : (int t * bool t) -> int = function | (Int,_) -> 0  | (_,Bool) -> .
  > 
  > let _f : (int t * bool t) -> int = function | (Int,_) -> 0
  > EOF

Check that the example typechecks
  $ ocamlc -stop-after typing test.ml
  $ export MUTAML_SEED=896745231
  $ export MUTAML_GADT=true
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 3 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type _ t =
    | Int: int t 
    | Bool: bool t 
  let _f : (int t * bool t) -> int =
    function
    | (Int, _) -> if __MUTAML_MUTANT__ = (Some "test:0") then 1 else 0
    | (_, Bool) -> .
    | _ -> .
  let _f : (int t * bool t) -> int =
    function
    | (Int, _) -> if __MUTAML_MUTANT__ = (Some "test:1") then 1 else 0
    | (_, Bool) -> .
  let _f : (int t * bool t) -> int =
    function | (Int, _) -> if __MUTAML_MUTANT__ = (Some "test:2") then 1 else 0




Another example from the manual:

  $ cat > test.ml <<'EOF'
  > type _ typ =
  >   | Int : int typ
  >   | String : string typ
  >   | Pair : 'a typ * 'b typ -> ('a * 'b) typ
  > 
  > let rec to_string: type t. t typ -> t -> string =
  >   fun t x ->
  >   match t with
  >   | Int -> Int.to_string x
  >   | String -> Printf.sprintf "%S" x
  >   | Pair(t1,t2) ->
  >       let (x1, x2) = x in
  >       Printf.sprintf "(%s,%s)" (to_string t1 x1) (to_string t2 x2)
  > EOF

Check that the example typechecks
  $ ocamlc -stop-after typing test.ml
  $ export MUTAML_SEED=896745231
  $ export MUTAML_GADT=true
  $ bash ../filter_dune_build.sh ./test.bc --instrument-with mutaml | sed '/fun x ->/d' | sed 's/fun t ->/fun t x ->/' | sed 's/     m/   m/' | sed 's/     |/   |/' | sed 's/ \{9\}/       /'
  Running mutaml instrumentation on "test.ml"
  Randomness seed: 896745231   Mutation rate: 100   GADTs enabled: true
  Created 0 mutations of test.ml
  Writing mutation info to test.muts
  
  let __MUTAML_MUTANT__ = Stdlib.Sys.getenv_opt "MUTAML_MUTANT"
  type _ typ =
    | Int: int typ 
    | String: string typ 
    | Pair: 'a typ * 'b typ -> ('a * 'b) typ 
  let rec to_string : type t. t typ -> t -> string =
    fun t x ->
      match t with
      | Int -> Int.to_string x
      | String -> Printf.sprintf "%S" x
      | Pair (t1, t2) ->
          let (x1, x2) = x in
          Printf.sprintf "(%s,%s)" (to_string t1 x1) (to_string t2 x2)
