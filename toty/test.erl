-module(test).

-export([run/4]).

% N = cantidad de workers (con sus respectivos managers)
% Sleep = tiempo de cuanto deben esperar los workers hasta el envío del siguiente mensaje
% Jitter = delay en entregar los mensajes
% WorkTime = tiempo en segundos que va a correr la app
run(N, Sleep, Jitter, WorkTime) ->
  Ms = startManagers(N, Jitter),
  Show = show:start(N),
  Workers = startWorkers(N, Sleep, Ms),
  initManagers(N, Workers, Ms, Ms, Show),
  timer:sleep(WorkTime * 1000),
  lists:foreach(
    fun(P) ->
      P ! stop 
    end, Ms ++ Workers ++ [Show]).

startManagers(0, _) ->
  [];
startManagers(N, Jitter) ->
  [toty:init(N, Jitter) | startManagers(N-1, Jitter)].

startWorkers(0, _, _) ->
  [];
startWorkers(N, Sleep, [M|Ms]) ->
  [worker:initWorker(integer_to_list(N), Sleep, M) | startWorkers(N-1, Sleep, Ms)].

initManagers(0, _, _, _, _) ->
  [];
initManagers(N, [W|Ws], [M|Ms], Managers, Show) ->
  M ! {start, W, Managers, Show},
  initManagers(N-1, Ws, Ms, Managers, Show).
