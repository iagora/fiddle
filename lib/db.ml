module type DB = sig
  type t
  val connect : string -> t
  val insert_cpf_and_digest : t -> string -> string -> unit
  val find_cpf_by_digest : t -> string -> string option
  val close : t -> unit
end

module SQLiteDB : DB = struct
  type t = Sqlite3.db

  let connect filename = Sqlite3.db_open filename

  let insert_cpf_and_digest db cpf digest =
    let sql = "INSERT INTO cpf_hashes (cpf, digest) VALUES (?, ?)" in
    let stmt = Sqlite3.prepare db sql in
    Sqlite3.bind_text stmt 1 cpf |> ignore;
    Sqlite3.bind_text stmt 2 digest |> ignore;
    match Sqlite3.step stmt with
    | Sqlite3.Rc.DONE -> ()
    | _ -> failwith "Insert failed"

  let find_cpf_by_digest db digest =
    let sql = "SELECT cpf FROM cpf_hashes WHERE digest = ?" in
    let stmt = Sqlite3.prepare db sql in
    Sqlite3.bind_text stmt 1 digest |> ignore;
    match Sqlite3.step stmt with
    | Sqlite3.Rc.ROW -> Some (Sqlite3.column_text stmt 0)
    | _ -> None

  let close db = if not (Sqlite3.db_close db) then failwith "couldn't close db"
end

