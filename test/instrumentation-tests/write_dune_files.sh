#!/bin/bash

#Create dune-project file
echo "(lang dune 2.9)" > dune-project

#Create a dune file enabling instrumentation
cat > dune <<'EOF'
(executable
 (name test)
 (modes byte)
 (ocamlc_flags -dsource)
 (instrumentation (backend mutaml))
)
EOF
