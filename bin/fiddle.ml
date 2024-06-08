open Lib
open Core

let list_algorithms_command =
  Command.basic ~summary:"list all supported hash algorithms"
    Command.Param.(return (fun () -> list_algorithms ()))

let process_cpfs_command =
  Command.basic ~summary:"process multiple CPFs from command line arguments"
    (let%map_open.Command cpfs = anon (sequence ("cpf" %: string))
     and hash_algorithm =
       flag "-hash" ~aliases:[ "-h" ]
         (optional_with_default "sha256" string)
         ~doc:
           "HASH specify the hash algorithm. Use --list-algorithms for a full \
            list"
     and mac_algorithm =
       flag "-mac" ~aliases:[ "-m" ] (optional string)
         ~doc:
           "MAC specify the MAC algorithm. Use --list-algorithms for a full \
            list. Secret key must be in FIDDLE_SECRET_KEY env var"
     and digest_length =
       flag "-length" ~aliases:[ "-l" ]
         (optional_with_default 512 int)
         ~doc:
           "LENGTH specify the digest length in bits for algorithms that have \
            varying length output"
     in
     fun () ->
       let f =
         match (hash_algorithm, mac_algorithm) with
         | hash, None -> hash_a_cpf hash digest_length
         | _, Some mac -> mac_a_cpf mac digest_length
       in
       List.iter cpfs ~f:(fun cpf ->
           let number = Int.of_string cpf in
           f number))

let process_stdin =
  Command.basic ~summary:"process CPFs straight from stdin"
    (let%map_open.Command hash_algorithm =
       flag "-hash" ~aliases:[ "-h" ]
         (optional_with_default "sha256" string)
         ~doc:
           "HASH specify the hash algorithm. Use --list-algorithms for a full \
            list."
     and mac_algorithm =
       flag "-mac" ~aliases:[ "-m" ] (optional string)
         ~doc:
           "MAC specify the MAC algorithm. Use --list-algorithms for a full \
            list. Secret key must be in FIDDLE_SECRET_KEY env var"
     and digest_length =
       flag "-length" ~aliases:[ "-l" ]
         (optional_with_default 512 int)
         ~doc:
           "LENGTH specify the digest length in bits for algorithms that have \
            varying length output"
     in
     fun () ->
       let f =
         match (hash_algorithm, mac_algorithm) with
         | hash, None -> hash_a_cpf hash digest_length
         | _, Some mac -> mac_a_cpf mac digest_length
       in
       In_channel.fold_lines In_channel.stdin ~init:() ~f:(fun () line ->
           let number = Int.of_string line in
           f number))

(* Entry point of the program *)
let () =
  Command.group ~summary:"fiddle"
    [
      ("stdin", process_stdin);
      ("process", process_cpfs_command);
      ("list-algorithms", list_algorithms_command);
    ]
  |> Command_unix.run
