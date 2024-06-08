open Lib
open Core

let list_algorithms_command =
  Command.basic
    ~summary:"List all supported hash algorithms"
    Command.Param.(
        return (fun () -> list_algorithms ())
    )

let process_cpf_command =
  Command.basic
    ~summary:"Calculate check digits and hash a single CPF number"
    (
      let%map_open.Command
        cpf = anon ("cpf" %: string)
        and hash_algorithm = flag "-hash" (optional_with_default "sha256" string)
                              ~doc:"Specify the hash algorithm. Use --list-algorithms for a full list."
        and mac_algorithm = flag "-mac" (optional string)
                              ~doc: "Specify the MAC algorithm. Use --list-algorithms for a full list."
        and digest_length = flag "-length" (optional_with_default 512 int)
                             ~doc:"Specify the digest length in bits."
      in
      fun () ->
          match hash_algorithm, mac_algorithm with
          | hash, None -> 
                  let number = Int.of_string cpf in
                  hash_a_cpf hash digest_length number 
          | _, Some mac ->
                  let number = Int.of_string cpf in
                  mac_a_cpf mac digest_length number 
    )

let process_multiple_cpfs_command =
  Command.basic
    ~summary:"Process multiple CPFs from command line arguments"
    (
      let%map_open.Command
        cpfs = anon (sequence ("cpf" %: string))
        and hash_algorithm = flag "-hash" (optional_with_default "sha256" string)
                              ~doc:"Specify the hash algorithm (sha256, blake2b)"
        and mac_algorithm = flag "-mac" (optional string)
                              ~doc: "Specify the MAC algorithm. Use --list-algorithms for a full list."
        and digest_length = flag "-length" (optional_with_default 512 int)
                             ~doc:"Specify the digest length in bits for Blake2b"
      in
      fun () ->
          let f = match hash_algorithm, mac_algorithm with
          | hash, None -> hash_a_cpf hash digest_length 
          | _, Some mac -> mac_a_cpf mac digest_length
          in
          List.iter cpfs ~f:(fun cpf ->
            let number = Int.of_string cpf in
              f number
        )
    )

let process_stdin =
  Command.basic
    ~summary:"Process CPFs straight from stdin"
    (
      let%map_open.Command
        hash_algorithm = flag "-hash" (optional_with_default "sha256" string)
                              ~doc:"Specify the hash algorithm (sha256, blake2b)"
        and mac_algorithm = flag "-mac" (optional string)
                              ~doc: "Specify the MAC algorithm. Use --list-algorithms for a full list."
        and digest_length = flag "-length" (optional_with_default 512 int)
                             ~doc:"Specify the digest length in bits for Blake2b"
      in
      fun () -> (
          let f = match hash_algorithm, mac_algorithm with
          | hash, None -> hash_a_cpf hash digest_length 
          | _, Some mac -> mac_a_cpf mac digest_length
          in
          In_channel.fold_lines In_channel.stdin ~init:() ~f:(fun () line ->
          let number = Int.of_string line in
          f number
       )
     )
    )

(* Entry point of the program *)
let () =
  Command.group ~summary:"fiddle"
    [
      ("single", process_cpf_command);
      ("multiple", process_multiple_cpfs_command);
      ("stdin", process_stdin);
      ("list-algorithms", list_algorithms_command);
    ]
  |> Command_unix.run
