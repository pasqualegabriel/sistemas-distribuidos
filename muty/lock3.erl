-module(lock3).

-export([start/1]).

start(Id) -> spawn(fun () -> init(Id) end).

init(Id) ->
    receive
      {peers, Peers} -> 
				open(Peers, Id, time:zero(Id));
      stop -> 
				ok
    end.

open(Nodes, Id, Clock) ->
    receive
      {take, Master, Name} -> % Master (=worker) quiere tomar el lock
        NewClock = time:inc(Id, Clock),
        contador ! {take, Name, time:nro(NewClock)},
        Refs = requests(Nodes, NewClock), % Manda request a los otros locks 
        wait(Nodes, Master, Refs, [], Id, NewClock, NewClock);
      {request, From, Ref, Clock_req} ->
        NewClock = time:inc(Id, time:merge(Clock, Clock_req)),
	      From ! {ok, Ref, NewClock}, 
        open(Nodes, Id, NewClock);
      stop -> 
        ok
    end.

requests(Nodes, Clock) ->
    lists:map(fun(P) ->
		      R = make_ref(), 
          P ! {request, self(), R, Clock}, 
          R
	      end,
	      Nodes).

wait(Nodes, Master, [], Waiting, Id, Clock, Initial_clock) ->
    contador ! {taken, Id, time:nro(Initial_clock), time:nro(Clock)},
    Master ! taken, 
    held(Nodes, Waiting, Id, Clock);
wait(Nodes, Master, Refs, Waiting, Id, Clock, Initial_clock) ->
    receive
      {request, From, Ref, Clock_req} ->
        NewClock = time:inc(Id, time:merge(Clock, Clock_req)),
        case time:priority(Clock_req, Initial_clock) of
          true -> % Clock_req tiene prioridad
            From ! {ok, Ref, NewClock}, % responde al lock 
            [Ref2] = requests([From], NewClock),
            wait(Nodes, Master, [Ref2 | Refs], Waiting, Id, NewClock, Initial_clock);
          _ -> % Tengo la prioridad, sigo esperando a los demas locks
            wait(Nodes, Master, Refs, [{From, Ref} | Waiting], Id, NewClock, Initial_clock)
        end;
      {ok, Ref, Clock_req} ->
        NewClock = time:inc(Id, time:merge(Clock, Clock_req)),
        Refs2 = lists:delete(Ref, Refs),
        wait(Nodes, Master, Refs2, Waiting, Id, NewClock, Initial_clock);
      release -> 
        ok(Waiting, Clock), 
        open(Nodes, Id, Clock)
    end.

ok(Waiting, Clock) ->
    lists:foreach(fun ({F, R}) -> F ! {ok, R, Clock} end, Waiting).

held(Nodes, Waiting, Id, Clock) ->
    receive
      {request, From, Ref, Clock_req} ->
        NewClock = time:inc(Id, time:merge(Clock, Clock_req)),
	      held(Nodes, [{From, Ref} | Waiting], Id, NewClock);
      release -> 
        ok(Waiting, Clock), 
        open(Nodes, Id, Clock)
    end.
