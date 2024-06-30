open Core
open Cryptokit

(* Hash hex encodings *)
let hash algorithm length data =
  let hash_function =
    match algorithm with
    | "sha3" -> Hash.sha3 length
    | "keccak" -> Hash.keccak length
    | "sha2" -> Hash.sha2 length
    | "sha224" -> Hash.sha224 ()
    | "sha256" -> Hash.sha256 ()
    | "sha384" -> Hash.sha384 ()
    | "sha512" -> Hash.sha512 ()
    | "blake2b" -> Hash.blake2b length
    | "blake2b512" -> Hash.blake2b512 ()
    | "blake2s" -> Hash.blake2s length
    | "blake2s256" -> Hash.blake2s256 ()
    | "blake3" -> Hash.blake3 length
    | "blake3_256" -> Hash.blake3_256 ()
    | "ripemd160" -> Hash.ripemd160 ()
    | "sha1" -> Hash.sha1 ()
    | "md5" -> Hash.md5 ()
    | _ -> failwith "Unsupported hash algorithm"
  in
  let digest =
    hash_function#add_string data;
    hash_function#result
  in
  transform_string (Hexa.encode ()) digest

let mac algorithm length data =
  let secret_key =
    match Sys.getenv "FIDDLE_SECRET_KEY" with
    | Some key -> transform_string (Base64.decode ()) key
    | None -> failwith "Environment variable FIDDLE_SECRET_KEY must be set."
  in
  let mac =
    match algorithm with
    | "sha1" -> MAC.hmac_sha1 secret_key
    | "sha256" -> MAC.hmac_sha256 secret_key
    | "sha384" -> MAC.hmac_sha384 secret_key
    | "sha512" -> MAC.hmac_sha512 secret_key
    | "ripemd160" -> MAC.hmac_ripemd160 secret_key
    | "md5" -> MAC.hmac_md5 secret_key
    | "blake2b" -> MAC.blake2b length secret_key
    | "blake2b512" -> MAC.blake2b512 secret_key
    | "blake2s" -> MAC.blake2s length secret_key
    | "blake2s256" -> MAC.blake2s256 secret_key
    | "blake3" -> MAC.blake3 length secret_key
    | "blake3_256" -> MAC.blake3_256 secret_key
    | "siphash" -> MAC.siphash secret_key
    | "siphash128" -> MAC.siphash128 secret_key
    | _ -> failwith "Unsupported MAC algorithm"
  in
  let result =
    mac#add_string data;
    mac#result
  in
  transform_string (Hexa.encode ()) result
