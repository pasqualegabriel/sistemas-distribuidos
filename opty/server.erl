-module(server).
-export([start/1]).

start(N) ->
    init_contador(),
    register(servidor, spawn(fun() -> init(N) end)).

init(N) ->
    Store = store:new(N),
    Validator = validator:start(),
    server(Validator, Store).

server(Validator, Store) ->
    receive
        {open, Client} ->
            Client ! {transaction, Validator, Store},
            server(Validator, Store);
        stop ->
            store:stop(Store),
            get_size ! bye
    end.


init_contador() ->
    register(contador, spawn(fun() -> contador(0, 0) end)).

contador(C, A) ->
    receive
        state ->
            io:format("Hay ~w transacciones commiteadas y ~w transacciones abortadas.~n", [C, A]),
            contador(C, A);
        ok -> contador(C + 1, A);
        abort -> contador(C, A + 1)
    end.

