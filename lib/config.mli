type t = {
  hash : string;
  mac : string option;
  length : int;
  mask : string;
  target : string option;
  np : int;
}

val fiddle : t -> unit
