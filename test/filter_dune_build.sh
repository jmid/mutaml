#!/usr/bin/env bash

# breakdown:
#   filter [@@@ocaml.ppx.context whitespace {  0-or-more not-close-brace-chars }]
#   and normalize file system paths
dune build $@ 2>&1 | \
    sed -E 'H;1h;$!d;x;s/\[@@@ocaml\.ppx\.context\n\ \ \{[^}]*\}\]//g' | \
    sed -E "/^\/usr\/bin\/ld/d" | \
    sed 's/home[^ ]*bin\//some\/path\/...\/bin\//' | \
    sed 's/Users[^ ]*bin\//some\/path\/...\/bin\//'
