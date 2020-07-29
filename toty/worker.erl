-module(worker).

-export([initWorker/3, start/8]).

initWorker(Id, Sleep, M) ->
    Gui = gui:start(Id),
    spawn(fun() -> start(Id, 1, M, Sleep, Gui, 0, 0, 0) end).

start(Id, N, Manager, Sleep, Gui, R, G, B) ->
	receive
        {Id2, N2, Show} -> 
            NewR = (R + random:uniform(50)) rem 255,
            Gui ! {R, G, B},
            Show ! {add, Id, Id2, N2},
            start(Id, N, Manager, Sleep, Gui, G, B, NewR);
        stop -> 
            Gui ! stop
    after random:uniform(Sleep) ->
        Manager ! {send, {Id, N}},
        start(Id, N + 1, Manager, Sleep, Gui, R, G, B)
	end.
