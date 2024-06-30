val cpf_to_digest : (string -> string) -> string -> string -> string option

val digest_to_cpf : (string -> string) -> string -> int * int -> string -> string option
