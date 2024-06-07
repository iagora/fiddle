(lang dune 3.15)

(name fiddle)

(generate_opam_files true)

(source
 (github iagora/fiddle))

(authors "iagora")

(maintainers "iagora")

(license LICENSE)

(documentation https://url/to/documentation)

(package
 (name fiddle)
 (synopsis "Product of boredom and OCaml curiosity")
 (description "This is a tool to play around with hashed CPFs (Cadastro Nacional de Pessoa Física), the Brazilian social security number")
 (depends ocaml dune)
 (tags
  (topics "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
