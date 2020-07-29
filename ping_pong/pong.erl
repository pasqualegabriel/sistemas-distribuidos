-module(pong).

%% API
-export([start_pong/0, pong/0]).

pong() ->
  receive
    {ping, X} ->
      io:format("Ping recieved from: ~w~n", [X]),
      io:format("Sending answer to: ~w~n", [X]),
      {ping, 'ping@gabi'} ! {pong, X},
      pong();
    X ->
      io:format("pong: X = ~w~n", [X]),
      pong()
  end.

start_pong() ->
  register(pong, spawn(pong, pong, [])).

