(** A minimal RNG interface  *)
include Random.State

let make_random_seed () = Random.State.bits (make_self_init ())
let init seed = Random.State.make [|seed|]
let int rs bound = int rs (bound+1)
