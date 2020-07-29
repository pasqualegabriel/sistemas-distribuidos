-module(gms3).
-export([startLeader/1, startSlave/2]).
-define(arghh, 50).
startLeader(Id) ->
  Self = self(),
  {ok, spawn_link(fun() -> init(Id, Self) end)}.

init(Id, Master) ->
  leader(Id, Master, 1, [], [Master]).

startSlave(Id, Group) ->
  Self = self(),
  {ok, spawn_link(fun() -> init(Id, Group, Self) end)}.

init(Id, Group, Master) ->
  Self = self(),
  Group ! {join, Master, Self},
  receive
    {view, N, [Leader | Slaves], Group2} ->
      Master ! {view, N, Group2},
      erlang:monitor(process, Leader),
      slave(Id, Master, Leader, N+1, {view, N, [Leader | Slaves], Group2}, Slaves, Group2)
  after 3 * 1000 ->
    Master ! {error, "no reply from leader"}

  end.

leader(Id, Master, N, Slaves, Group) ->
  receive
    {mcast, Msg} ->
      bcast(Id, {msg, N, Msg}, Slaves),
      Master ! Msg,
      leader(Id, Master, N + 1, Slaves, Group);
    {join, Wrk, Peer} ->
      Slaves2 = lists:append(Slaves, [Peer]),
      Group2 = lists:append(Group, [Wrk]),
      bcast(Id, {view, N, [self() | Slaves2], Group2}, Slaves2),
      Master ! {view, N, Group2},
      leader(Id, Master, N + 1, Slaves2, Group2);
    stop -> ok
  end.

slave(Id, Master, Leader, N, Last, Slaves, Group) ->
  receive
    {mcast, Msg} ->
      Leader ! {mcast, Msg},
      slave(Id, Master, Leader, N, Last, Slaves, Group);
    {join, Wrk, Peer} ->
      Leader ! {join, Wrk, Peer},
      slave(Id, Master, Leader, N, Last, Slaves, Group);
    {msg, I, _} when I < N ->
      io:format("Yo: ~s, estaba esperando el mensaje: ~w pero me llego el ~w~n", [Id, N, I]),
      slave(Id, Master, Leader, N, Last, Slaves, Group);
    {msg, M, Msg} ->
      Master ! Msg,
      slave(Id, Master, Leader, M + 1, {msg, M, Msg}, Slaves, Group);
    {view, I, _, _} when I < N ->
      slave(Id, Master, Leader, N, Last, Slaves, Group);
    {view, M, [Leader | Slaves2], Group2} ->
      Master ! {view, M, Group2},
      slave(Id, Master, Leader, M + 1, {view, M, [Leader | Slaves2], Group2}, Slaves2, Group2);
    {'DOWN', _Ref, process, Leader, _Reason} ->
      election(Id, Master, N, Last, Slaves, Group);
    stop ->
      ok
  end.

election(Id, Master, N, Last, Slaves, [_ | Group]) ->
  Self = self(),
  case Slaves of
    [Self | Rest] ->
      bcast(Id, Last, Rest),
      bcast(Id, {view, N, Slaves, Group}, Rest),
      Master ! {view, N, Group},
      io:format("esto es lo que borad cuando me vuelvo lider: ~w, en el momento: ~w~n.", [Last, N]),
      leader(Id, Master, N + 1, Rest, Group);
    [Leader | Rest] ->
      erlang:monitor(process, Leader),
      slave(Id, Master, Leader, N, Last, Rest, Group)
  end.

bcast(Id, Msg, Nodes) ->
  lists:foreach(fun(Node) -> Node ! Msg, crash(Id) end, Nodes).
crash(Id) ->
  case random:uniform(?arghh) of
    ?arghh ->
      io:format("leader ~s: crash~n", [Id]),
      exit(no_luck);
    _ -> ok
  end.
