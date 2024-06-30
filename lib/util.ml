let int_to_cpf_array n =
  let open Core in
  Printf.sprintf "%09d" n |> String.to_list
  |> List.map ~f:(fun c -> Char.to_int c - Char.to_int '0')

(* Function to calculate the CPF check digits *)
let calculate_cpf_digits cpf_base =
  let open Core in
  (* Helper to calculate a single digit based on the cpf array and the weights *)
  let calc_digit weights cpf_numbers =
    List.fold2_exn cpf_numbers weights ~init:0 ~f:(fun acc x weight ->
        acc + (x * weight))
    |> fun sum ->
    let remainder = sum % 11 in
    if remainder < 2 then 0 else 11 - remainder
  in
  (* Weights for the first and second check digits *)
  let weights_first = [ 10; 9; 8; 7; 6; 5; 4; 3; 2 ] in
  let weights_second = [ 11; 10; 9; 8; 7; 6; 5; 4; 3; 2 ] in
  (* Calculate the first check digit *)
  let first_digit = calc_digit weights_first cpf_base in
  (* Calculate the second check digit *)
  let complete_cpf = cpf_base @ [ first_digit ] in
  (* Include first check digit in the list *)
  let second_digit = calc_digit weights_second complete_cpf in
  (* Now using complete_cpf *)
  (first_digit, second_digit)

(* Convert integer list to CPF string *)
let cpf_list_to_string cpf_digits (d1, d2) =
  let open Core in
  List.fold cpf_digits ~init:"" ~f:(fun acc x -> acc ^ Int.to_string x)
  |> fun base_str -> Printf.sprintf "%s-%d%d" base_str d1 d2

let cpu_count () =
  try
    match Sys.os_type with
    | "Win32" -> int_of_string (Sys.getenv "NUMBER_OF_PROCESSORS")
    | _ -> (
        let i = Unix.open_process_in "getconf _NPROCESSORS_ONLN" in
        let close () = ignore (Unix.close_process_in i) in
        let ib = Scanf.Scanning.from_channel i in
        try
          Scanf.bscanf ib "%d" (fun n ->
              close ();
              n)
        with e ->
          close ();
          raise e)
  with
  | Not_found | Sys_error _ | Failure _ | Scanf.Scan_failure _ | End_of_file
  | Unix.Unix_error (_, _, _)
  ->
    1
