.PHONY: test
all:
	dune build

test:
	dune test

clean:
	rm -f *~ src/*~ src/common/*~ src/ppx/*~ src/report/*~ src/runner/*~
	rm -f test/*~ test/instrumentation-tests.t/*~ test/negative-tests/*~
	rm -f test/testproj-1-module.t/*~ test/testproj-2-modules.t/*~ output*.txt
	dune clean
