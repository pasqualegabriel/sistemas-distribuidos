-module(rudy).
-import(http, [parse_request/1]).
-export([start/2, stop/0, init/2, handler/1, stop_all/2]).

init(Port, N) ->
  Opt = [list, {active, false}, {reuseaddr, true}],
  case gen_tcp:listen(Port, Opt) of
    {ok, Listen} ->
      Pids = handlers(Listen, N),
      register(stop_all, spawn(rudy, stop_all, [Listen, [self() | Pids]])),
      io:format("PID stop all: ~w~n", [whereis(stop_all)]),
      handler(Listen),
      ok;
    {error, Error} ->
      error
  end.

handlers(_, 1) -> [];
handlers(Listen, N) when N > 1 ->
  Pid = spawn(rudy, handler, [Listen]),
  io:format("PID handler: ~w~n", [Pid]),
  [Pid | handlers(Listen, N - 1)].

stop_all(Listen, Pids) ->
  receive
    stop ->
      io:format("stopping~n"),
      gen_tcp:close(Listen),
      io:format("Cerro gen_tcp~n"),
      delete_pids(Pids),
      io:format("Elimino pids~n"),
      io:format("Eliminando ~w~n", [self()]),
      exit("time to die"),
      io:format("Elimino todo~n");
    _ ->
      stop_all(Listen, Pids)
  end.

delete_pids([]) -> ok;
delete_pids([Pid | Pids]) ->
  io:format("Elimino pid ~w~n", [Pid]),
  exit(Pid, "handler delete"),
  delete_pids(Pids).

handler(Listen) ->
  io:format("~w, levanto un handler~n", [self()]),
  case gen_tcp:accept(Listen) of
    {ok, Client} ->
      io:format("~w, recibi req~n", [self()]),
      request(Client,[]),
      handler(Listen);
    {error, Error} ->
      error
  end.

request(Client, Parsed_Str) ->
  Recv = gen_tcp:recv(Client, 0),
  case Recv of
    {ok, Str} ->
      [A, B, C, D | _] = lists:reverse(Str),
      if not ((A == C) and (C == 10) and (B == D) and (D == 13)) ->
          request(Client, lists:append([Parsed_Str, Str]));
        true ->
          Request = parse_request(Str),
          Response = reply(Request),
          gen_tcp:send(Client, Response)
      end;
    {error, Error} ->
      io:format("rudy: error: ~w~n", [Error])
  end,
  gen_tcp:close(Client).

reply({{get, URI, _}, _, _}) ->
  timer:sleep(1 * 1000),
  http:ok("ALoha desdeeeeee").

start(Port, N) ->
  register(rudy, spawn(fun() -> init(Port, N) end)),
  io:format("PID rudy: ~w~n", [whereis(rudy)]).

stop() ->
  stop_all ! stop.
