Check that report tool fails without finding JSON file:
  $ mutaml-report
  Attempting to read from mutaml-report.json...
  Could not open file mutaml-report.json: No such file or directory
  [1]

Check that report tool fails without finding another inexisting JSON file:
  $ mutaml-report foobar.json
  Attempting to read from foobar.json...
  Could not open file foobar.json: No such file or directory
  [1]

Create a non-JSON file:
  $ cat > invalid-input.txt <<'EOF'
  > - finn : 42th birthday
  > - remember to buy toiletpaper
  > - æøå
  > EOF

Check that it was created:
  $ ls invalid-input.txt
  invalid-input.txt

Try to parse `invalid-input.txt` as JSON:
  $ mutaml-report invalid-input.txt
  Attempting to read from invalid-input.txt...
  Could not parse JSON in invalid-input.txt: Invalid JSON
  [1]

Create a JSON file in the wrong format:
  $ cat > mydoc.json <<'EOF'
  > { "finn" : 42;
  >   "john" : [1;2;3;true]
  > }
  > EOF

Check that it was created:
  $ ls mydoc.json
  mydoc.json

Now confirm that it is rejected by the report tool:
  $ mutaml-report mydoc.json
  Attempting to read from mydoc.json...
  Could not parse JSON in mydoc.json: Invalid JSON
  [1]
