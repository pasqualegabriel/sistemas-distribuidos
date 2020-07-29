-module(handler).
-export([start/3]).

start(Client, Validator, Store) ->
  spawn_link(fun() -> init(Client, Validator, Store) end).

init(Client, Validator, Store) ->
  handler(Client, Validator, Store, [], []).

handler(Client, Validator, Store, Reads, Writes) ->
  receive
    {read, Ref, N} ->
      case lists:keysearch(N, 1, Writes) of
        {value, {N, _, Value}} ->
          Client ! {value, Ref, Value},
          handler(Client, Validator, Store, Reads, Writes);
        false ->
          Entry = store:lookup(N, Store),
          Entry ! {read, Ref, self()},
          handler(Client, Validator, Store, Reads, Writes)
      end;
    {Ref, Entry, Value, Time} ->
      Client ! {value, Ref, Value},
      handler(Client, Validator, Store, [{Entry, Time} | Reads], Writes);
    {write, N, Value} ->
      Added = [{N, store:lookup(N, Store), Value} | Writes],
      handler(Client, Validator, Store, Reads, Added);
    {commit, Ref} ->
      Validator ! {validate, Ref, Reads, Writes, Client};
    state ->
      io:format("Handler: -Status ~n Reads: ~w ~n Writes: ~w~n", [Reads, Writes]),
      print_store(Store),
      handler(Client, Validator, Store, Reads, Writes);
    abort ->
      io:format("Handler: -Abortando transaccion", []),
      ok
  end.

print_store(Store) ->
  io:format("Handler: -El estado actual del store es~n"),
  lists:foreach(fun(Entry) -> Entry ! print end, tuple_to_list(Store)).
