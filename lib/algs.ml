open Core

let list_algorithms () =
  let hash_algorithms =
    [
      "Hash algorithms:";
      "";
      "\tsha3";
      "\tkeccak";
      "\tsha2";
      "\tsha224";
      "\tsha256";
      "\tsha384";
      "\tsha512";
      "\tblake2b";
      "\tblake2b512";
      "\tblake2s";
      "\tblake2s256";
      "\tblake3";
      "\tblake3_256";
      "\tripemd160";
      "\tsha1";
      "\tmd5";
    ]
  in
  let mac_algorithms =
    [
      "MAC algorithms:";
      "";
      "\tsha256";
      "\tsha384";
      "\tsha512";
      "\tblake2b";
      "\tblake2b512";
      "\tblake2s";
      "\tblake2s256";
      "\tblake3";
      "\tblake3_256";
      "\tripemd160";
      "\tsiphash";
      "\tsiphash128";
      "\tsha1";
      "\tmd5";
    ]
  in
  let open Stdio in
  List.iter ~f:(printf "%s\n") hash_algorithms;
  printf "\n";
  List.iter ~f:(printf "%s\n") mac_algorithms
