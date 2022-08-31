
let header_to_string (name, value) = name ^ ": " ^ value

(* Default action: Return the request URI,method,Host,Headers and Body. *)
(* Return:
   ---
   URI: http(s)://{domain, localhost,...}:{80,443,8080,...}/...
   HTTP(S) Method: {GET, POST, PUT, PATCH, DELETE, ...}
   HTTP(S) Host: {server-name, whoami.txt, localhost, ...}
   HTTP(S) Headers: {Accept: */*, User-Agent: ..., ...}
*)
(* TODO: Fix URI's domain... Should get from client reqeust if possible. *)
let display_request_info req =
  let open Lwt.Syntax in
  let+ req_body = Dream.body req in
  Dream.response
  @@ Printf.sprintf "
URI: http%s://%s%s
Method: %s
Version: HTTP/%s
Headers: ---
%s
Body: ---
%s\n
"
    (if Dream.tls req then "s" else "")
    ("localhost")
    (Dream.target req)
    (Dream.method_to_string @@ Dream.method_ req)
    (if Dream.tls req then "2.0" else "1.1")
    (String.concat "\n" @@ List.map header_to_string @@ Dream.all_headers req)
    req_body

(* Show the content fo whomai.txt. *)
let display_whoami _req =
  let open Lwt.Syntax in
  let+ whoami =
    try
      let ic = open_in "whoami.txt" in
      try
        let s = input_line ic in
        close_in ic;
        Lwt_result.return s
      with e -> close_in_noerr ic; raise e
    with e -> Lwt_result.fail (Printexc.to_string e)
  in
  if Result.is_ok whoami then (
    Dream.log "The file has been read successfully, Cotents: %s" (Result.get_ok whoami);
    Dream.response @@ Result.get_ok whoami)
  else (
    Dream.warning (fun log -> log "%s" (Result.get_error whoami));
    Dream.response "")

(* Show the specific environment variable. *)
let display_env_variable req =
  let open Lwt.Syntax in
  let var_name = Dream.param req "variable" in
  let+ var_val =
    try
      Lwt_result.return (Sys.getenv var_name)
    with e -> Lwt_result.fail (Printexc.to_string e)
  in
  if Result.is_ok var_val then (  
    Dream.log "The environment variable '%s' has been gotten successfully, value: %s" var_name (Result.get_ok var_val);
    Dream.response @@ Result.get_ok var_val)
  else (
    Dream.log "The environment variable '%s' does not exist" var_name;
    Dream.response ~status:`Not_Found "")

(* Show the env command result. *)
let display_envs _req =
  let open Lwt.Syntax in
  let+ envs =
    try
      (* Note:
          in_chan: The standard output of the command is redirected to a pipe, which can be read via the returned input channel(in_chan).
          out_chan: Data written to the returned output channel(out_chan) is sent to the standard input of the command.
          ---
          Reference: https://ocaml.org/api/Unix.html
      *)
      let (in_chan, out_chan, err_chan) = Unix.open_process_full "env" [||] in
      let rec read_chan in_chan result =
        try
          let r = input_line in_chan in
          read_chan in_chan (r :: result)
        with
        | End_of_file -> List.rev result
      in
      match (read_chan in_chan [], read_chan err_chan []) with
      | (output, []) ->
        let _ = Unix.close_process_full (in_chan, out_chan, err_chan) in        
        Lwt_result.return (String.concat "\n" output)
      | ([], output) ->
        let _ = Unix.close_process_full (in_chan, out_chan, err_chan) in
        Lwt_result.fail (String.concat "\n" output)
      | (_, _) ->
        let _ = Unix.close_process_full (in_chan, out_chan, err_chan) in
        Lwt_result.fail "Unknown error"
    with e -> Lwt_result.fail (Printexc.to_string e)
  in
  if Result.is_ok envs then (
    Dream.log "The environment variables has been gotten successfully, value: '%s'" (Result.get_ok envs);
    Dream.response @@ Result.get_ok envs)
  else (
    Dream.log "The env command has been failed, error: %s" (Result.get_error envs);
    Dream.response ~status:`Internal_Server_Error "")

(* Show the expression for status code(status code) and return its code. *)
let display_status_code req =
  let code = Dream.param req "code" |> int_of_string in
  let status = code |> Dream.int_to_status in
  match (Dream.status_to_reason status) with
    | Some rsn -> Dream.respond ~status:status @@ Printf.sprintf "Code: %d\nReason: %s\n" code rsn
    | None -> Dream.respond ~status:`Not_Implemented @@ Printf.sprintf "Such status code(%d) is not implemented.\n" code

let display_ok_status _ =
  Dream.respond @@ "200"

(* Wait for the number of seconds in path parameter.
   If the number of seconds is negative, wait 0 seconds.
*)
let delay_response req =
  let open Lwt.Syntax in
  let second = Dream.param req "second" |> float_of_string in
  let+ wait =  Lwt_unix.sleep second in
  (wait;
  Dream.response @@ Printf.sprintf "Waited for %.0f seconds.\n" second)

(* Basic authorize based on user name and password in path parameters. *)
let verify_basic_auth req =
  let req_user = Dream.param req "user" in
  let req_pass = Dream.param req "password" in
  Dream.header req "Authorization"
  |> (fun a -> match a with
      | Some bauth ->
        (* Separate "Basic" and Base64 encoded string. *)
        let enc = String.split_on_char ' ' bauth |> List.tl |> String.concat "" in
        let dcd = Base64.decode_exn enc in
        (* Separate user-id and password by ":" *)
        let str_list = String.split_on_char ':' dcd in
        let user = List.hd str_list in
        let pass = List.tl str_list |> String.concat ":" in
        if (req_user, req_pass) = (user, pass) then
          Dream.respond @@ Printf.sprintf "Accepted user: %s\n" user
        else (
          Dream.log "Authentication failed, req_user:%s, user: %s" req_user user;
          Dream.respond ~status:`Unauthorized "")
      | None -> (
          Dream.log "Authentication header not found";
          Dream.respond ~status:`Unauthorized ""))

(* Main *)
let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.router [
    Dream.get "/" display_request_info;

    Dream.get "/whoami" display_whoami;
    Dream.get "/whoami/" display_whoami;

    Dream.get "/envs" display_envs;
    Dream.get "/envs/" display_envs;

    Dream.get "/envs/:variable" display_env_variable;
    Dream.get "/envs/:variable/" display_env_variable;

    Dream.get "/statuses/:code" display_status_code;
    Dream.get "/statuses/:code/" display_status_code;
    Dream.get "/health" display_ok_status;
    Dream.get "/health/" display_ok_status;

    Dream.get "/delay/:second" delay_response;
    Dream.get "/delay/:second/" delay_response;

    Dream.get "/basic-auth/:user/:password" verify_basic_auth;
    Dream.get "/basic-auth/:user/:password/" verify_basic_auth;
  ]
