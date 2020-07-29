-module(loggy).
-export([start/1, stop/1]).

start(Nodes) ->
  spawn_link(fun() -> init(Nodes) end).

stop(Logger) ->
  Logger ! stop.

init(Nodes) ->
  register(contador, spawn_link(fun() -> init_count() end)),
  loop([], time:clock(Nodes)).

loop(Queue, Clock) ->
  receive
    {log, From, Time, Msg} ->
      contador ! add,
      NewClock = time:update(Time, Clock),
      loop(print_safes_keep_no_safes(sort([{From, Time, Msg} | Queue]), NewClock), NewClock);
    stop ->
      print(sort(Queue))
  end.


sort(Queue) -> lists:sort(fun({_, T, _}, {_, T2, _}) -> time:leq(T, T2) end, Queue).

print_safes_keep_no_safes(Queue, Clock) ->
  lists:foldl(fun({F, T, M}, Acc) ->
    case time:safe(T, Clock) of
      true ->
        log(F, T, M),
        Acc;
      _ ->
        [{F, T, M} | Acc]
    end
              end, [], Queue).

print(Queue) ->
  contador ! {print_state, length(Queue)},
  lists:foreach(
    fun({From, Time, Msg}) ->
      io:format("Cola de Retencion, from: ~w, time: ~w, Msg: ~w ~n", [From, Time, Msg])
    end
    , Queue).

log(From, Time, Msg) ->
  io:format("log: ~w ~w ~p~n", [Time, From, Msg]).


init_count() ->
  count(0).

count(N) ->
  receive
    add ->
      count(N + 1);
    {print_state, Q} ->
      io:format("Fueron ~w mensajes, y quedaron ~w en la cola de retencion.~n", [N, Q]);
    stop ->
      stop
  end.