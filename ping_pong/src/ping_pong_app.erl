%%%-------------------------------------------------------------------
%% @doc ping_pong public API
%% @end
%%%-------------------------------------------------------------------

-module(ping_pong_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    ping_pong_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
