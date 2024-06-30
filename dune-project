(lang dune 3.15)

(name fiddle)

(generate_opam_files true)

(source
 (github iagora/fiddle))

(authors "iagora")

(maintainers "iagora")

(license LICENSE)

(documentation https://github.com/iagora/fiddle)

(package
 (name fiddle)
 (synopsis "Product of boredom and OCaml curiosity")
 (description "This is a tool to play around with hashed CPFs (Cadastro Nacional de Pessoa Física), the Brazilian social security number")
 (depends
   ocaml
   dune
   (cryptokit (>= 1.19))
   (core (>= 0.17.1))
   (core_unix (>= 0.17.0))
   (sqlite3 (= 5.1.0)))
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
