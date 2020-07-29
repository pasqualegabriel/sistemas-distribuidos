-module(time).
-export([zero/1, inc/2, merge/2, leq/2, priority/2, nro/1]).

zero(Id) -> {Id, 0}.

inc(Id, {_, T}) -> {Id, T + 1}.

merge(Ti, Tj) -> 
  case leq(Ti, Tj) of 
    true ->
      Tj;
    _ ->
      Ti
  end.

leq({_, Ti}, {_, Tj}) -> Ti =< Tj.

% True si el primero tiene prioridad
% en caso de igualdad, el menor Id tiene prioridad
priority({Idi, Ti}, {Idj, Tj}) -> 
  (Ti < Tj) or ((Ti == Tj) and (Idi < Idj)).

nro({_, T}) -> T.
