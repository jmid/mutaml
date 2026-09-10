Next release
------------

- Support ppxlib 0.37 and 0.38 and require dune.3.22.0 #49
- Adjust test suite to be compatible with >= dune.3.22.0 #48
- Switch to using `ppx_deriving_yojson` instead of `ppx_yojson_conv` #47
- Use dune.3.18 support to generate `x-maintenance-intent` entry #45
- Patch `ppx_yojson_conv` dependency which was missing a `v`-prefix #43
- Introduce a `mutaml.opam.template` to avoid opam linting failure #41
- Adjust RE to support `runtest` on OpenBSD too #40
- Remove `which` and `conf-which` dependency #39
- Support ppxlib.0.34 and runtest on OCaml 5.3 #36

0.3
---

- Avoid mutations in attribute parameters #29
- Avoid polymorphic equality which is incompatible with Core #30

0.2
---

- Add support for ppxlib.0.28 and above #27
- Avoid triggering 2 mutations of a pattern incl. a when-clause
  causing a redundant sub-pattern warning #22, #23

0.1
---

- Initial opam release of `mutaml`
