.PHONY: test
test:
	dune test

mutamltest:
	dune build test/ounittest.exe --instrument-with mutaml
	mutaml-runner "dune exec --no-build test/ounittest.exe"
	mutaml-report

clean:
	rm -rf *~ src/*~ test/*~ _mutations mutaml-report.json
	dune clean
