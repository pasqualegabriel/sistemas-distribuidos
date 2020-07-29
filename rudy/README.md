RUDY
=====

Mejoras
=====
Una de las mejoras que implementamos para el web-server, fue la de tener un pool de handlers para poder procesar request en simultaneo. Lo implementamos creando un proceso por cada handler:
```erlang
handlers(_, 1) -> [];
handlers(Listen, N) when N > 1 ->
  Pid = spawn(rudy, handler, [Listen]),
  io:format("PID handler: ~w~n", [Pid]),
  [Pid | handlers(Listen, N - 1)].
```
 el init recibe la cantidad que queremos tener y los instancia mientras guarda los pids para despues poder _matarlos_
 
```erlang
init(Port, N) ->
  Opt = [list, {active, false}, {reuseaddr, true}],
  case gen_tcp:listen(Port, Opt) of
    {ok, Listen} ->
      Pids = handlers(Listen, N),
      register(stop_all, spawn(rudy, stop_all, [Listen, [self() | Pids]])),
      io:format("PID stop all: ~w~n", [whereis(stop_all)]),
      handler(Listen),
      ok;
    {error, Error} ->
      error
  end.
```

Entendimos que esto es una mejor opcion en algunos casos, ya que no esta tan bueno levantar procesos sin tener ningun
tipo de chequeo. Si bien es _barato_ levantar procesos, puede llegar a traernos complicaciones.

Pruebas
=======
Para poder realizar pruebas con el modulo `test`, lo tuvimos que modificar para que haga las request de forma paralela. La implementacion es similar a la del pool de handlers,
creamos un proceso por cada request en este caso:
```erlang

multiple_bench(Host, Port, 1) ->
    spawn(test, request, [Host, Port]);
multiple_bench(Host, Port, N) when N > 1 ->
    spawn(test, request, [Host, Port]),
    multiple_bench(Host, Port, N - 1).
```

El start del test, lo usa mientras se comunica con (o crea si es necesario) un proceso que usamos como _timer_, porque nos encontramos con el problema de que como la request sucede
en un proceso aparte necesitabamos una forma de poder controlar el tiempo que tarde en ser respondida.

```erlang
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
``` 

Resultados
=====
Un ejemplo para levantar el servidor en el puerto `8080` que pueda manejar `2` requests en simultaneo usamos con el comando: 
`$ rudy:start(8080, 2).`
Teniendo en cuenta que cada request tiene un sleep de 1 segundo, al realizar 10 requests paralamente (utilizando el comando `$ test:start(8080, 10`) vemos que tarda `5 segundos` en completar todas las requests y luego si realizamos la misma prueba levantando el servidor que pueda manejar `5` requests en simultaneo vemos que tarda `2 segundos`.

Dudas
=====
* Como hacer mapping a URL (/foo¿?).

Pendiente
==========
Una de las cosas que tambien intentamos mejorar fue el hecho de que la request podria no venir toda dentro del mismo paquete. Para eso hicimos que siga recibiendo paquetes en el socket con 
`gen_tcp:recv` hasta que encuentre un doble `CRLF` :

```erlang
request(Client, Parsed_Str) ->
  Recv = gen_tcp:recv(Client, 0),
  case Recv of
    {ok, Str} ->
      [A, B, C, D | _] = lists:reverse(Str),
      if not ((A == C) and (C == 10) and (B == D) and (D == 13)) ->
          request(Client, lists:append([Parsed_Str, Str]));
        true ->
          Request = parse_request(Str),
          Response = reply(Request),
          gen_tcp:send(Client, Response)
      end;
    {error, Error} ->
      io:format("rudy: error: ~w~n", [Error])
  end,
  gen_tcp:close(Client).
```

Esto no se llego a probar...pero igual nos gustaria saber si es correcto o no. Y en caso de que no, cual es el error.


Build
-----

    $ rebar3 compile
