-module(time).
-export([zero/1, inc/2, merge/2, leq/2, clock/1, update/2, safe/2]).

zero(Name) -> {Name, 0}.

inc(Name, {_, T}) -> {Name, T + 1}.

merge(Ti, Tj) -> 
  case leq(Ti, Tj) of 
    true ->
      Tj;
    _ ->
      Ti
  end.

leq({_, Ti}, {_, Tj}) -> Ti =< Tj.

clock(Nodes) -> 
  lists:map(fun(Node) -> zero(Node) end, Nodes).

update({Node, Time}, Clock) ->
  lists:map(fun({N, T}) ->
    if 
      Node == N -> {N, Time};
      true -> {N, T}
    end
  end, Clock).

safe({_, Time}, Clock) -> lists:min(lists:map(fun({_, T}) -> T end, Clock)) > Time.
