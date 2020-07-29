-module(client).
-define(Opt, [binary, {packet, 0}, {exit_on_close,false}, {reuseaddr, true}, {active, true}, {nodelay, true}, {keepalive,true}]).
-define(TimeOut, 10000).
%% API
-export([init/2]).
init(Proxy, Port) ->
  {ok, Listen} = gen_tcp:listen(Port, ?Opt),
  {ok, Socket} = gen_tcp:accept(Listen),
  case read_request(Socket) of
    {ok, _, _} ->
      case connect(Proxy) of
        {ok, N, Context} ->
          send_reply(Context, Socket),
          {ok, Msg} = loop(N, Socket),
          io:format("client: terminating~s~n", [Msg]);
        {error, Error} ->
          io:format("client: ~s~n", [Error])
      end;
    {error, Error} ->
      io:format("client: ~s~n", [Error])
  end.

connect(Proxy) ->
  Proxy ! {request, self()},
  receive
    {reply, N, Context} ->
      {ok, N, Context}
  after ?TimeOut ->
    {error, "time out"}
  end.

loop(_, Socket) ->
  io:format("client: -Entre al loop~n"),
  receive
    {data, N, Data} ->
      io:format("Llego data~n"),
      send_data(Data, Socket),
      loop(N + 1, Socket);
    {tcp_closed, Socket} ->
      {ok, "player closed connection"}
  after ?TimeOut ->
    {ok, "time out"}
  end.
send_data(Data, Socket) ->
  icy:send_data(Data, fun(Bin) -> gen_tcp:send(Socket, Bin) end).
send_reply(Context, Socket) ->
  io:format("client: -voy a enviar una reply~n"),
  icy:send_reply(Context, fun(Bin) -> gen_tcp:send(Socket, Bin) end).
read_request(Socket) ->
  reader(fun() -> icy:request(<<>>) end, Socket).

reader(Cont, Socket) ->
  case Cont() of
    {ok, Parsed, Rest} ->
      {ok, Parsed, Rest};
    {more, Fun} ->
      receive
        {tcp, Socket, More} ->
          reader(fun() -> Fun(More) end, Socket);
        {tcp_closed, Socket} ->
          {error, "server closed connection"}
      after ?TimeOut ->
        {error, "time out"}
      end;
    {error, Error} ->
      {error, Error}
  end.