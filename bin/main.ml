open Base
open Stdio
open Lib

(* Entry point of the program *)
let () =
  In_channel.input_lines In_channel.stdin
  |> List.iter ~f:(fun line ->
      let number = Int.of_string line in
      calculate_a_cpf number
    )
