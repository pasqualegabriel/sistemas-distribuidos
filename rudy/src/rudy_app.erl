%%%-------------------------------------------------------------------
%% @doc rudy public API
%% @end
%%%-------------------------------------------------------------------

-module(rudy_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    rudy_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
