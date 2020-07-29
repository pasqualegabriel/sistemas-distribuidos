-module(consumer).

%% API
-export([start/1, stop/0]).


start(Producer) ->
  register(consumer, spawn(fun() -> init(Producer) end)).

stop() ->
  consumer ! bye.




init(Producer) ->
  Monitor = monitor(process, Producer),
  Producer ! {hello, self()},
  wait_for_ping(0, Monitor).

wait_for_ping(N, Monitor) ->
  receive
    {ping, X} when X == N ->
      io:format("Recibi ping correcto: ~w~n", [N]),
      wait_for_ping(N + 1, Monitor);
    {ping, X} when X =/= N ->
      io:format("WARNING, ping incorrecto, esperaba ~w, pero recibi ~w .~n", [N, X]),
      wait_for_ping(N + 1, Monitor);
    {'DOWN', Monitor, process, Object, Info} ->
      io:format("~w died; ~w~n", [Object, Info]),
      wait_for_ping(N, Monitor);
    bye ->
      self() ! exit
  end.