-module(lock2).

-export([start/1]).

start(Id) -> spawn(fun () -> init(Id) end).

init(Id) ->
    receive
      {peers, Peers} -> open(Peers, Id);
      stop -> ok
    end.

open(Nodes, Id) ->
    receive
      {take, Master, _} -> % Master (=worker) quiere tomar el lock
        Refs = requests(Nodes, Id), % Manda request a los otros locks 
        wait(Nodes, Master, Refs, [], Id);
      {request, From, Ref, _} ->
	      From ! {ok, Ref}, 
        open(Nodes, Id);
      stop -> 
        ok
    end.

requests(Nodes, Id) ->
    lists:map(fun (P) ->
		      R = make_ref(), 
          P ! {request, self(), R, Id}, 
          R
	      end,
	      Nodes).

wait(Nodes, Master, [], Waiting, Id) ->
    Master ! taken, 
    held(Nodes, Waiting, Id);
wait(Nodes, Master, Refs, Waiting, Id) ->
    receive
      {request, From, Ref, Id_req} ->
        if 
          Id > Id_req -> % Id_req tiene prioridad
            From ! {ok, Ref}, % responde al lock 
            [Ref2] = requests([From], Id), % como Id_req va a entrar primero,
            % le envio un request para que cuando salga, mande un ok
            % agrego Ref2 y espero el ok
            wait(Nodes, Master, [Ref2 | Refs], Waiting, Id);
          true -> % Tengo la prioridad, sigo esperando a los demas locks
            wait(Nodes, Master, Refs, [{From, Ref} | Waiting], Id)
        end;
      {ok, Ref} ->
        Refs2 = lists:delete(Ref, Refs),
        wait(Nodes, Master, Refs2, Waiting, Id);
      release -> 
        ok(Waiting), 
        open(Nodes, Id)
    end.

ok(Waiting) ->
    lists:foreach(fun ({F, R}) -> F ! {ok, R} end, Waiting).

held(Nodes, Waiting, Id) ->
    receive
      {request, From, Ref, _} ->
	      held(Nodes, [{From, Ref} | Waiting], Id);
      release -> 
        ok(Waiting), 
        open(Nodes, Id)
    end.
