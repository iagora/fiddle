open Lib
open Core

let process_cpf_command =
  Command.basic
    ~summary:"Calculate check digits and hash a single CPF number"
    (
      let%map_open.Command
        cpf = anon ("cpf" %: string)
        and hash_algorithm = flag "-hash" (optional_with_default "sha256" string)
                              ~doc:"Specify the hash algorithm (sha256, blake2b)"
        and digest_length = flag "-length" (optional_with_default 512 int)
                             ~doc:"Specify the digest length in bits for Blake2b"
      in
      fun () ->
        let number = Int.of_string cpf in
          calculate_a_cpf number hash_algorithm digest_length
    )

let process_multiple_cpfs_command =
  Command.basic
    ~summary:"Process multiple CPFs from command line arguments"
    (
      let%map_open.Command
        cpfs = anon (sequence ("cpf" %: string))
        and hash_algorithm = flag "-hash" (optional_with_default "sha256" string)
                              ~doc:"Specify the hash algorithm (sha256, blake2b)"
        and digest_length = flag "-length" (optional_with_default 512 int)
                             ~doc:"Specify the digest length in bits for Blake2b"
      in
      fun () ->
        List.iter cpfs ~f:(fun cpf ->
            let number = Int.of_string cpf in
              calculate_a_cpf number hash_algorithm digest_length
        )
    )

let process_stdin =
  Command.basic
    ~summary:"Process CPFs straight from stdin"
    (
      let%map_open.Command
        hash_algorithm = flag "-hash" (optional_with_default "sha256" string)
                              ~doc:"Specify the hash algorithm (sha256, blake2b)"
        and digest_length = flag "-length" (optional_with_default 512 int)
                             ~doc:"Specify the digest length in bits for Blake2b"
      in
      fun () -> (
       In_channel.fold_lines In_channel.stdin ~init:() ~f:(fun () line ->
       let number = Int.of_string line in
       calculate_a_cpf number hash_algorithm digest_length
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
    ]
  |> Command_unix.run
