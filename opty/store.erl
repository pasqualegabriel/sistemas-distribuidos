-module(store).
-export([new/1, stop/1, lookup/2, size/0, size/1]).


new(N) ->
    Pid = spawn_link(fun() -> store:size(N)end),
    register(get_size, Pid),
    list_to_tuple(entries(N, [])).

stop(Store) ->
    lists:map(fun(E) -> E ! stop end, tuple_to_list(Store)).

lookup(I, Store) ->
    element(I, Store). % this is a builtin function

entries(N, Sofar) ->
    if
        N == 0 ->
            Sofar;
        true ->
            Entry = entry:new(0),
            entries(N - 1, [Entry | Sofar])
    end.

size() ->
    get_size ! {size, self()},
    receive
        {size, N} -> N
    end.

size(N) ->
    receive
        {size, From} ->
            From ! {size,N},
            store:size(N);
        bye -> ok
    end.