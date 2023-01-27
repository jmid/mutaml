(** A minimal RNG interface  *)
type t
val make_random_seed : unit -> int
val int  : t -> int -> int
val init : int -> t
val copy : t -> t
