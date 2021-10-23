.PHONY: test
test:
	dune test

mutamltest:
	dune build ./ounittest.exe --instrument-with mutaml
	mutaml-runner "dune exec --no-build ./ounittest.exe"
	mutaml-report

clean:
	rm -rf *~ _mutations mutaml-report.json
	dune clean
