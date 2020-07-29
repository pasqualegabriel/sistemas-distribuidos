-module(client).

%% API
-export([open/1, init/2, read/2, write/3, commit/1, abort/1, state/1, make_lots_of_transactions/4, start_concurrent/1]).

init(Server, Name) ->
  Server ! {open, self()},
  receive
    {transaction, Validator, Store} ->
      Handler = handler:start(self(), Validator, Store),
      register(Name, Handler),
      io:format("instancie el handle: ~w ~n", [Handler])
  end.

open(Server) ->
  Server ! {open, self()},
  receive
    {transaction, Validator, Store} ->
      Handler = handler:start(self(), Validator, Store),
      Size = store:size(),
      make_lots_of_transactions(0, Size, erlang:system_time(milli_seconds), Handler)
  end.


read(N, Handler) ->
  Referencia = make_ref(),
  Handler ! {read, Referencia, N},
  receive
    {value, Ref, Value} -> io:format("Cliente: -Pude leer la celda ~w-esima, su valor es: ~w. ~n", [N, Value])
  end.

write(N, Value, Handler) ->
  Handler ! {write, N, Value}.

commit(Handler) ->
  Ref = make_ref(),
  Handler ! {commit, Ref},
  receive
    {Ref, ok} -> contador ! ok;
    {Ref, abort} -> contador ! abort
  end.

abort(Handler) ->
  io:format("Cliente: -Abortando"),
  Handler ! abort.

state(Handler) ->
  io:format("Cliente: -Stateando"),
  Handler ! state.

%%N = cantidad de transacciones que va haciendo
%%X = tamaño store
%%T = Tiempo en milisegundos de inicio.
make_lots_of_transactions(N, X, T, Handleador) ->
  Rem = rand:uniform(X),
  ErlangsystemTime = erlang:system_time(milli_seconds),
  Op = rand:uniform(5),
  if ErlangsystemTime >= T + 1000 ->
    commit(Handleador),
    io:format("paso 1 segundo, hice ~w request. ~n", [N]);
    (Op == 2) or (Op == 4) ->
      read(Rem, Handleador),
      make_lots_of_transactions(N + 1, X, T, Handleador);
    (Op == 1) or (Op == 3) ->
      write(Rem, 99, Handleador),
      make_lots_of_transactions(N + 1, X, T, Handleador);
    Op == 5 ->
      commit(Handleador)
  end.

start_concurrent(0) ->
  ok;

start_concurrent(N) ->
  spawn(fun() -> open(servidor) end),
  start_concurrent(N - 1).