-module(test).
-export([startLeader/2, startSlave/3]).

startLeader(Id, Module) ->
  spawn(fun() -> init(Id, Module) end).

init(Id, Module) ->
  Gui = gui:start(Id),
  {_, Nodo_del_grupo} = apply(Module, startLeader, [Id]),
  io:format("Nodo del grupo: ~w~n", [Nodo_del_grupo]),
  init_loop(Id, Nodo_del_grupo, Gui).

startSlave(Id, Module, Group) ->
  spawn(fun() -> initSlave(Id, Module, Group) end).

initSlave(Id, Module, Group) ->
  {_, Nodo_del_grupo} = apply(Module, startSlave, [Id, Group]),
  io:format("Nodo del grupo: ~w~n", [Nodo_del_grupo]),
  receive
    {view, _} ->
      Gui = gui:start(Id),
      init_loop(Id, Nodo_del_grupo, Gui);
    {view, _, _} ->
      Gui = gui:start(Id),
      init_loop(Id, Nodo_del_grupo, Gui)
  end.

init_loop(Id, Nodo_del_grupo, Gui) ->
  receive
    {view, _} ->
      init_loop(Id, Nodo_del_grupo, Gui);
    {view, _, _} ->
      init_loop(Id, Nodo_del_grupo, Gui);
    {send, M} ->
      Nodo_del_grupo ! {mcast, M},
      init_loop(Id, Nodo_del_grupo, Gui);
    {color, Color} ->
      Gui ! Color,
      init_loop(Id, Nodo_del_grupo, Gui);
    stop ->
      Nodo_del_grupo ! stop,
      Gui ! stop,
      ok;
    grupo ->
      io:format("Nodo del grupo: ~w~n", [Nodo_del_grupo]),
      init_loop(Id, Nodo_del_grupo, Gui);
    _ ->
      init_loop(Id, Nodo_del_grupo, Gui)
  end.
