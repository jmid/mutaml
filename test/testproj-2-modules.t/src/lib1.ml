let rec fac n = match n with
  | 0 -> 1
  | _ -> n * fac (n-1)
