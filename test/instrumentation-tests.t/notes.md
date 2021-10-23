--------------------------------------------------------------------------------

Addendum:

Unfortunately, many of these pattern mutations are invalid in the
presence of GADTs -- see gadts.t for examples.

--------------------------------------------------------------------------------


Mutating pattern matching:
==========================

How can the following program be mutated?

> let () = match !Sys.interactive with
>   | true  -> print_endline "Running interactively"
>   | false -> print_endline "Running in batch mode"

We could (1) collapse cases using or-patterns:

> let () = match !Sys.interactive with
>   | true
>   | false -> print_endline "Running interactively"

or we could (2) swap right-hand-sides (since no variables are bound in either pattern):

> let () = match !Sys.interactive with
>   | true  -> print_endline "Running in batch mode"
>   | false -> print_endline "Running interactively"


The former could be achieved as follows:

> let () =
>   if __MUTAML_MUTANT__ = (Some "test:27")
>   then
>     (match !Sys.interactive with
>       | true
>       | false -> print_endline "Running interactively")
>   else
>     (match !Sys.interactive with
>       | true  -> print_endline "Running interactively"
>       | false -> print_endline "Running in batch mode")

This has the disadvantage of duplication, with a worst-case quadratic blow-up.
By moving the test inside the right-hand-side there is less duplication, but still some:

> let () =
>   (match !Sys.interactive with
>     | true  ->
>       (if __MUTAML_MUTANT__ = (Some "test:27")
>        then print_endline "Running interactively"
>        else print_endline "Running in batch mode")
>     | false -> print_endline "Running in batch mode")

With a guarded pattern match we can avoid most duplication however:

> let () =
>   (match !Sys.interactive with
>     | true when __MUTAML_MUTANT__ <> (Some "test:27")
>       -> print_endline "Running interactively"
>     | true
>     | false -> print_endline "Running in batch mode")

Note: there is still duplication of the matched pattern,
which we deem acceptable for now.


Generalizing the type and pattern match

> type t = A | B | C
>
> match f x with
> | A -> g y
> | B -> h z
> | C -> i q

we arrive at

> match f x with
> | A when __MUTAML_MUTANT__ <> (Some "test:27") -> g y
> | A
> | B when __MUTAML_MUTANT__ <> (Some "test:45") -> h z
> | B
> | C -> i q

This should also work in the presence of data:

> type t = A | B of bool
>
> match f x with
> | A -> g y
> | B true  -> h z
> | B false -> h' z'

where we expect:

> match f x with
> | A -> g y
> | B true when __MUTAML_MUTANT__ <> (Some "test:27") -> h z
> | B true
> | B false -> h' z'


and with nested matches with either wildcards:

> type t = A of int*int | B
>
> match f x with
> | A (0,_) -> g0 y0
> | A (_,1) -> g1 y1
> | A p -> gp yp p
> | B   -> h z

or with the same variable bound by the same constructor:

> type t = A of int*int | B
>
> match f x with
> | A (0,x) -> g0 y0 x
> | A (1,x) -> g1 y1 x
> | A p -> gp yp p
> | B   -> h z

where we expect:

> match f x with
> | A (0,x) when __MUTAML_MUTANT__ <> (Some "test:27") -> g0 y0 x
> | A (0,x)
> | A (1,x) -> g1 y1 x
> | A p -> gp yp p
> | B   -> h z

The variable requirement ensures syntactically that 'x' has the same
type in both cases, without typing information present.

A better typing approximation could loosen this requirement



The special case of exception patterns can just be filtered out and moved last (or first):

> type t = A | B | C
>
> match f x with
> | A -> g y
> | Exception Error -> foo bar
> | B -> h z
> | C -> i q

yielding

> match f x with
> | A when __MUTAML_MUTANT__ <> (Some "test:27") -> g y
> | A
> | B when __MUTAML_MUTANT__ <> (Some "test:45") -> h z
> | B
> | C -> i q
> | Exception Error -> foo bar



Overall mutation (1) - merge-into-or-pattern:
* collapse two consecutive pattern-match cases into an or-pattern
* requirement: no variables are bound in either
*         -or- same constructor, with same variables bound in both + same positions, recursively


Overall mutation (2) - rhs-swapping:
* Swap right-hand sides of two consecutive pattern-match cases
* same requirement



Mutation idea: drop a pattern when a later pattern is catch all _:
==================================================================

> match f x with
> | A -> g y
> | B -> h z
> | _ -> i q

which can be achieved as:

> match f x with
> | A when __MUTAML_MUTANT__ <> (Some "test:27") -> g y
> | B when __MUTAML_MUTANT__ <> (Some "test:45") -> h z
> | _ -> i q

Only do so for matches with at least 3 cases?
With only 2 cases present, removing 1 to leave a catch-all case
seems like an unlikely programming error to make:

>   let is_some opt = match opt with
> -   | Some _ -> true
>     | _      -> false

The approach also works for or-patterns:

> match f x with
> | A | B -> g y
> | C -> h z
> | _ -> i q

and for nested ones:

> match f x with
> | A (D | E) -> g y
> | C -> h z
> | _ -> i q


There is a special case of exception patterns:

> match f x with
> | exception Not_found -> e q
> | A -> g y
> | B -> h z
> | _ -> i q

which we filter out and put last:

> match f x with
> | A when __MUTAML_MUTANT__ <> (Some "test:27") -> g y
> | B when __MUTAML_MUTANT__ <> (Some "test:45") -> h z
> | _ -> i q
> | exception Not_found -> e q


Overall mutation:
* drop a pattern-match case
* requirement: a _-pattern is present
