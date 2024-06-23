(* Define a type for the mask elements *)
type mask_element = Static of char | Charset of string

(* Function to parse a mask string into mask elements *)
let parse_mask mask =
  let rec aux i acc =
    if i >= String.length mask then List.rev acc
    else
      match mask.[i] with
      | '?' ->
          if i + 1 < String.length mask then
            match mask.[i + 1] with
            | 'l' -> aux (i + 2) (Charset "abcdefghijklmnopqrstuvwxyz" :: acc)
            | 'u' -> aux (i + 2) (Charset "ABCDEFGHIJKLMNOPQRSTUVWXYZ" :: acc)
            | 'd' -> aux (i + 2) (Charset "0123456789" :: acc)
            | 's' ->
                aux (i + 2) (Charset "!@#$%^&*()-_=+[]{}|;:',.<>?/~`" :: acc)
            | '?' -> aux (i + 2) (Static '?' :: acc)
            | _ -> invalid_arg "Invalid mask"
          else invalid_arg "Invalid mask"
      | c -> aux (i + 1) (Static c :: acc)
  in
  aux 0 []

(* Function to recursively generate and print combinations from a mask *)
let rec generate_and_print_combinations elements acc =
  match elements with
  | [] -> print_endline acc
  | Static c :: rest ->
      generate_and_print_combinations rest (acc ^ String.make 1 c)
  | Charset cs :: rest ->
      String.iter
        (fun c -> generate_and_print_combinations rest (acc ^ String.make 1 c))
        cs

(* Function to start the generation and printing process *)
let print_combinations mask =
  generate_and_print_combinations (parse_mask mask) ""

(* Example usage *)
let () =
  if Array.length Sys.argv <> 2 then prerr_endline "Usage: mascaml <mask>"
  else
    let mask = Sys.argv.(1) in
    print_combinations mask
