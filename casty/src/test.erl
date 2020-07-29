-module(test).
-define(Cast, {cast,"cdn.instream.audio", 9288, "/stream"}).
-define(Port, 3001).
%% API
-export([direct/0]).
direct() ->
  Proxy = spawn(proxy, init, [?Cast]),
  Dist = spawn(dist, init, [Proxy]),
  spawn(client, init, [Dist, ?Port]),
  spawn(client, init, [Dist, 3002]),
  spawn(client, init, [Dist, 3003]).