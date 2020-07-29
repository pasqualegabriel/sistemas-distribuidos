-module(proxy).
-define(TimeOut, 10000).
%% API
-export([init/1, send_request/3]).

init(Cast) ->
  receive
    {request, Client} ->
      io:format("proxy: received request ~w~n", [Client]),
      Ref = erlang:monitor(process, Client),
      case attach(Cast, Ref) of
        {ok, Stream, Cont, Context} ->
          io:format("proxy: attached ~n", []),
          Client ! {reply, 0, Context},
          {ok, Msg} = loop(Cont, 0, Stream, Client, Ref),
          io:format("proxy: terminating ~s~n", [Msg]);
        {error, Error} ->
          io:format("proxy: error ~s~n", [Error])
      end
  end.

loop(Cont, N, Stream, Client, Ref) ->
  case reader(Cont, Stream, Ref) of
    {ok, Data, Rest} ->
      Client ! {data, N, Data},
      loop(Rest, N + 1, Stream, Client, Ref);
    {error, Error} ->
      {ok, Error}
  end.

attach({cast, Host, Port, Feed}, Ref) ->
  io:format("Entra en attach ~n"),
  case gen_tcp:connect(Host, Port, [binary, {packet, 0}]) of
    {ok, Stream} ->
      io:format("Se conecto ~n"),
      case send_request(Host, Feed, Stream) of
        ok ->
          case reply(Stream, Ref) of
            {ok, Cont, Context} ->
              {ok, Stream, Cont, Context};
            {error, Error} ->
              {error, Error}
          end;
        _ ->
          {error, "unable to send request"}
      end;
    _ ->
      {error, "unable to connect to server"}
  end.
send_request(Host, Feed, Stream) ->
  icy:send_request(Host, Feed, fun(Bin) ->
    gen_tcp:send(Stream, Bin) end).

reader(Cont, Stream, Ref) ->
  case Cont() of
    {ok, Parsed, Rest} ->
      io:format("Parsed: ~w~n", [Parsed]),
      {ok, Parsed, Rest};
    {more, Fun} ->
      receive
        {tcp, Stream, More} ->
          reader(fun() -> Fun(More) end, Stream, Ref);
        {tcp_closed, Stream} ->
          {error, "icy server closed connection"};
        {'DOWN', Ref, process, _, _} ->
          {error, "client died"}
      after ?TimeOut ->
        {error, "time out"}
      end;
    {error, Error} ->
      {error, Error}
  end.

reply(Stream, Ref) ->
  reader(fun() -> icy:reply(<<>>) end, Stream, Ref).