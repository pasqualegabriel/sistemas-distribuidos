-module(dist).

%% API
-export([loop/3, init/1]).


-define(TimeOut, 10000).

init(Proxy) ->
  Proxy ! {request, self()},
  receive
    {reply, N, Context} ->
      loop([], N, Context)
  after ?TimeOut ->
    ok
  end.

loop(Clients, N, Context) ->
  receive
    {data, N, Data} ->
      lists:foreach(fun(Cliente) -> Cliente ! {data, N, Data} end, Clients),
      loop(Clients, N + 1, Context);
    {request, From} ->
      From ! {reply, N, Context},
      loop([From | Clients], N, Context);
    {'DOWN', _, process, _, _} ->
      loop(Clients, N, Context);
    stop ->
      {ok, "stoped"};
    stat ->
      loop(Clients, N, Context)
  end.