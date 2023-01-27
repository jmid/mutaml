(** A minimal RNG interface  *)
include Random4.State

let make_random_seed () = Random4.State.(bits (make_self_init ()))
let init seed = Random4.State.make [|seed|]
let int rs bound = int rs (bound+1)
