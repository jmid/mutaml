#!/bin/bash

#Create dune-project file
cat > dune-project << EOF
(lang dune 2.9)
EOF

#Create a dune file enabling instrumentation
cat > dune <<EOF
(executable
 (name test)
 (modes byte)
 (ocamlc_flags -dsource)
 (instrumentation (backend mutaml)))
EOF
