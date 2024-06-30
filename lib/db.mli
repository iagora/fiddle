module type DB = sig
  type t
  val connect : string -> t
  val insert_cpf_and_digest : t -> string -> string -> unit
  val find_cpf_by_digest : t -> string -> string option
  val close : t -> unit
end

module SQLiteDB : DB
