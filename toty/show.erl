-module(show).

-export([start/1, init/2]).

start(N) ->
  spawn(fun() -> init(N, []) end).

init(N, Messages) ->
  receive
    {add, Id, Id2, M} ->
      init(N, Messages ++ [{Id, Id2, M}]);
    stop ->
      {Errors, Total} = printArrays(N, filter(listN(N), Messages)),
      io:format("~w errores de ~w mensajes~n", [Errors, Total])
  end.

listN(0) ->
  [];
listN(N) ->
  [integer_to_list(N) | listN(N-1)].

filter([], _) -> [];
filter(_, []) -> [];
filter([N|Ns], Ms) ->
  [lists:filter(fun({Id, _, _}) -> N == Id end, Ms) | filter(Ns, Ms)].

printArrays(_, []) -> {0,0};
printArrays(N, Ms) ->
  case lists:any(fun(Xs) -> length(Xs) == 0 end, Ms) of
    true -> 
      printArrays(N, []);
    false -> 
      printN(N, lists:reverse(Ms)),
      [Xs | _] = Ms,
      [{_, XId2, XN2} | _] = Xs,
      case lists:all(fun(X) -> X == XId2 end, lists:map(fun({_, Id2, _}) -> Id2 end, first(Ms))) and
          lists:all(fun(X) -> X == XN2 end, lists:map(fun({_, _, N2}) -> N2 end, first(Ms))) of
        true ->
          {E, T} = printArrays(N, deleteFirst(Ms)),
          {E, T + 1};
        false ->
          {E, T} = printArrays(N, deleteFirst(Ms)),
          {E + 1, T + 1}
      end
  end.

printN(1, [Ms|_]) ->
  [{Id, Id2, N2} | _] = Ms,
  io:format("Yo(~s), De: ~s, Msg: ~w~n", [Id, Id2, N2]);
printN(N, [Ms|Mss]) -> 
  [{Id, Id2, N2} | _] = Ms,
  io:format("Yo(~s), De: ~s, Msg: ~w ------ ", [Id, Id2, N2]),
  printN(N-1, Mss).

first(Ms) -> lists:map(fun([M|_]) -> M end, Ms).

deleteFirst(Ms) -> lists:map(fun([_|Ns]) -> Ns end, Ms).
