-module(test).
-export([start/2, multiple_bench/3, run/3, start_timer/1, request/2]).

multiple_bench(Host, Port, 1) ->
    spawn(test, request, [Host, Port]);
multiple_bench(Host, Port, N) when N > 1 ->
    spawn(test, request, [Host, Port]),
    multiple_bench(Host, Port, N - 1).

start(Port, N) ->
    case whereis(timer) of 
        Pid when is_pid(Pid) ->
            io:format("updating start timer pid: ~w~n", [Pid]),
            timer ! update_start;
        _ ->
            io:format("Register timer ~n"),
            Start = erlang:system_time(micro_seconds),
            register(timer, spawn(test, start_timer, [Start])),
            io:format("timer pid: ~w~n", [whereis(timer)])
    end,
    multiple_bench("localhost", Port, N).

start_timer(Start) ->
    receive
        finish ->
            Finish = erlang:system_time(micro_seconds),
            io:format("Tarde: ~w~n", [Finish - Start]),
            start_timer(Start);
        update_start ->
            New_start = erlang:system_time(micro_seconds),
            start_timer(New_start);
        stop ->
            ok;
        _ ->
            start_timer(Start)
    end.

run(N, Host, Port) ->
    if
        N == 0 ->
            ok;
        true ->
            request(Host, Port),
            run(N-1, Host, Port)
    end.

request(Host, Port) ->
    Opt = [list, {active, false}, {reuseaddr, true}],
    {ok, Server} = gen_tcp:connect(Host, Port, Opt),
    gen_tcp:send(Server, http:get("foo")),
    Recv = gen_tcp:recv(Server, 0),
    case Recv of
        {ok, _} ->
            ok;
        {error, Error} ->
            io:format("test: error: ~w~n", [Error])
    end,
    timer ! finish,
    gen_tcp:close(Server).
