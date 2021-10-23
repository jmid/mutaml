#!/bin/bash

# breakdown:
#   filter [@@@ocaml.ppx.context whitespace {  0-or-more not-close-brace-chars }]
#   and normalize file system paths
dune build $@ 2>&1 | sed  -Ez 's/\[@@@ocaml\.ppx\.context\s+\{[^}]*\}\]//g' | sed 's/home[^ ]*bin\//home\/...\/bin\//'
