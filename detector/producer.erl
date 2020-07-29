-module(producer).

%% API
-export([start/1, stop/0, crash/0]).

start(Delay) ->
  Producer = spawn(fun() -> init(Delay) end),
  register(producer, Producer).

stop() ->
  producer ! stop.

crash() ->
  producer ! crash.

init(Delay) ->
  receive
    {hello, Consumer} ->
      producer(Consumer, 0, Delay);
    stop ->
      ok
  end.

producer(Consumer, N, Delay) ->
  receive
    stop ->
      Consumer ! bye;
    crash ->
      42/0 %% this will give you a warning, but it is ok
  after Delay ->
    Consumer ! {ping, N},
    producer(Consumer, N+1, Delay)
  end.

