-module(ping).

%% API
-export([ping/0, send_ping/0]).
ping() ->
  receive
    {pong, X} ->
      io:format("pong recieved: X = ~w~n", [X]),
      ping();
    X ->
      io:format("ping: X = ~w~n", [X]),
      ping()
  end.

send_ping() ->
  register(ping, spawn(ping, ping, [])),
  {pong, 'pong@gabi'} ! {ping, '1234'}.
