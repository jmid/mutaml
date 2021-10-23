Check that only the `report-negtests.t` file is present:
  $ ls
  report-negtests.t

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

Try to parse `report-negtests.t` as JSON:
  $ mutaml-report report-negtests.t
  Attempting to read from report-negtests.t...
  Could not parse JSON in report-negtests.t: Invalid JSON
  [1]

Create a JSON file in the wrong format:
  $ cat > mydoc.json <<'EOF'
  > { "finn" : 42;
  >   "john" : [1;2;3;true]
  > }
  > EOF

Check that it was created:
  $ ls
  mydoc.json
  report-negtests.t

Now confirm that it is rejected by the report tool:
  $ mutaml-report mydoc.json
  Attempting to read from mydoc.json...
  Could not parse JSON in mydoc.json: Invalid JSON
  [1]
