open Core
open Stdio

let int_to_cpf_array n =
  Printf.sprintf "%09d" n |> String.to_list
  |> List.map ~f:(fun c -> Char.to_int c - Char.to_int '0')

(* Function to calculate the CPF check digits *)
let calculate_cpf_digits cpf_base =
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
  List.fold cpf_digits ~init:"" ~f:(fun acc x -> acc ^ Int.to_string x)
  |> fun base_str -> Printf.sprintf "%s-%d%d" base_str d1 d2

let digest_to_cpf f target_result =
  let rec search n =
    if n > 999999999 then None (* Limiting the range for simplicity *)
    else
      let cpf_base = int_to_cpf_array n in
      let digits = calculate_cpf_digits cpf_base in
      let cpf_str = cpf_list_to_string cpf_base digits in
      let current_hash = f cpf_str in
      if String.equal current_hash target_result then Some cpf_str
      else search (n + 1)
  in
  let cpf =
    match search 0 with
    | Some data -> data
    | None -> failwith "Couldn't find CPF with matching digest"
  in
  printf "%s\n" cpf

let cpf_to_digest f number =
  let cpf_base = int_to_cpf_array number in
  let digits = calculate_cpf_digits cpf_base in
  let cpf_str = cpf_list_to_string cpf_base digits in
  let digest = f cpf_str in
  printf "%s\t%s\n" cpf_str digest
