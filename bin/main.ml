open Lib
open Core

let process_cpf_command =
  Command.basic
    ~summary:"Calculate check digits and hash a single CPF number"
    (
      let%map_open.Command
        cpf = anon ("cpf" %: string)
      in
      fun () ->
        let number = Int.of_string cpf in
        calculate_a_cpf number
    )

let process_multiple_cpfs_command =
  Command.basic
    ~summary:"Process multiple CPFs from command line arguments"
    (
      let%map_open.Command
        cpfs = anon (sequence ("cpf" %: string))
      in
      fun () ->
        List.iter cpfs ~f:(fun cpf ->
            let number = Int.of_string cpf in
             calculate_a_cpf number
        )
    )

let process_stdin =
  Command.basic
    ~summary:"Process CPFs straight from stdin"
    (
      let%map_open.Command () = return () in
      fun () -> (
       In_channel.fold_lines In_channel.stdin ~init:() ~f:(fun () line ->
       let number = Int.of_string line in
       calculate_a_cpf number
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
