type parameters = {
  hash : string;
  mac : string option;
  length : int;
  mask : string;
  target : string option;
}

type config = { param : parameters; range : (int * int) option }
type msg = Msg of string | Proc of config | Quit
type task = Search | Inputs

module Worker : sig
  type t = { pid : int; out_chan : out_channel }

  val worker_loop : in_channel -> unit

  val mk : unit -> t
  
  val send : t -> msg -> unit

  val kill : t -> unit
  val wait : t -> unit
end

