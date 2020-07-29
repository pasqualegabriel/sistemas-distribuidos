-module(muty).

-export([start/3, stop/0, stop/1, init_contador/2]).

start(Lock, Sleep, Work) ->
    register(contador, spawn(muty, init_contador, [[], 4])),
    L1 = apply(Lock, start, [1]),
    L2 = apply(Lock, start, [2]),
    L3 = apply(Lock, start, [3]),
    L4 = apply(Lock, start, [4]),
    L1 ! {peers, [L2, L3, L4]},
    L2 ! {peers, [L1, L3, L4]},
    L3 ! {peers, [L1, L2, L4]},
    L4 ! {peers, [L1, L2, L3]},
    register(w1, worker:start("John  ", L1, 34, Sleep, Work)),
    register(w2, worker:start("Ringo ", L2, 37, Sleep, Work)),
    register(w3, worker:start("Paul  ", L3, 43, Sleep, Work)),
    register(w4, worker:start("George", L4, 72, Sleep, Work)),
    timer:sleep(10 * 1000),
    stop(),
    ok.

stop() ->
    stop(w1), stop(w2), stop(w3), stop(w4).

stop(Name) ->
    case whereis(Name) of
        undefined ->
            ok;
        Pid ->
            Pid ! stop
    end.

init_contador(Takens, N) -> 
    receive
        {take, Name, Time} ->
            init_contador([{Name, "TAKE ", Time, Time} | Takens], N);
        {taken, Id, Time, Fin} ->
            case Id of
                1 -> init_contador([{"John  ", "taken", Time, Fin} | Takens], N);
                2 -> init_contador([{"Ringo ", "taken", Time, Fin} | Takens], N);
                3 -> init_contador([{"Paul  ", "taken", Time, Fin} | Takens], N);
                4 -> init_contador([{"George", "taken", Time, Fin} | Takens], N)
            end;
        stop -> 
            if 
                N == 1 ->
                    {ok, File} = file:open("test.csv", [write]),
                    csv_gen:row(File, ["name", "action", "init", "fin"]),
                    lists:foreach(fun({S, T, M, F}) -> 
                        io:format("~s, ~s, ~w, ~w~n", [S, T, M, F]),
                        csv_gen:row(File, [S, T, M, F])
                    end, lists:reverse(Takens)),
                    file:close(File);
                N > 1 ->
                    init_contador(Takens, N - 1)
            end
    end.
