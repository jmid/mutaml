Check that only the `runner-negtests.t` file is present:
  $ ls
  runner-negtests.t

Check that report tool fails when run without a test command:
  $ mutaml-runner
  Usage: mutaml-runner [options] <test-command>
  [1]

Try to supply an invalid command as argument, but still missing a mutation file:
  $ mutaml-runner scooby-doo.sh
  Could not read file mutaml-mut-files.txt - _build/default/mutaml-mut-files.txt: No such file or directory
  [1]

Now create the missing mutation file:
  $ mkdir -p _build/default
  $ touch _build/default/mutaml-mut-files.txt
and try again:
  $ mutaml-runner scooby-doo.sh
  No files were listed in mutaml-mut-files.txt
  [1]

Create a mutation file with a non-existing entry:
  $ cat > _build/default/mutaml-mut-files.txt <<'EOF'
  > somefile.muts
  > EOF
and try again:
  $ mutaml-runner scooby-doo.sh
  read mut file somefile.muts
  Could not read file somefile.muts - _build/default/somefile.muts: No such file or directory
  [1]

Create a corresponding mutation file with an empty list of mutations:
  $ cat > _build/default/somefile.muts <<'EOF'
  > []
  > EOF

Check that it was created:
  $ ls _build/default
  mutaml-mut-files.txt
  somefile.muts

Now confirm that it is rejected by the report tool:
  $ mutaml-runner scooby-doo.sh
  read mut file somefile.muts
  Warning: No mutations were listed in somefile.muts
  Did not find any mutations across the files listed in mutaml-mut-files.txt
  [1]

Create a corresponding mutation file with a dummy mutation:
  $ cat > _build/default/somefile.muts <<'EOF'
  > [{ "number" : 0,
  >    "repl"   : "false",
  >    "loc"    : {
  >      "loc_start" : { "pos_fname" : "somefile.ml", "pos_lnum" : 1, "pos_bol" : 1, "pos_cnum" : 1 },
  >      "loc_end"   : { "pos_fname" : "somefile.ml", "pos_lnum" : 2, "pos_bol" : 2, "pos_cnum" : 2 },
  >      "loc_ghost" : false
  >   }
  > }]
  > EOF
Now try running again with a broken command:
  $ mutaml-runner scooby-doo.sh
  read mut file somefile.muts
  Testing mutant somefile:0 ... Command not found: failed to run the test command "scooby-doo.sh"
  [1]



Run with an unknown build context passed as environment variable:
  $ export MUTAML_BUILD_CONTEXT="_build/in-a-galaxy-far-far-away"
  $ mutaml-runner true
  Could not read file mutaml-mut-files.txt - _build/in-a-galaxy-far-far-away/mutaml-mut-files.txt: No such file or directory
  [1]



Run with an unknown build context passed as command line option:
  $ mutaml-runner -build-context _build/foofoo true
  Could not read file mutaml-mut-files.txt - _build/foofoo/mutaml-mut-files.txt: No such file or directory
  [1]
