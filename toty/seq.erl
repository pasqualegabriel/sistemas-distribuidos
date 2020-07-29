-module(seq).
-export([new/1, increment/1, max/2, lessthan/2, maxId/2]).

new(Id) ->
	{0, Id}.

increment({Pn, Pi}) ->
	{Pn + 1, Pi}.

max(Proposal, Sofar) ->
	case lessthan(Proposal, Sofar) of
		true ->
			Sofar;
		false ->
			Proposal
	end.

lessthan({Pn, Pi}, {Nn, Ni}) ->
	(Pn < Nn) or ((Pn == Nn) and (Pi < Ni)).

maxId({P, PId}, {S, SId}) ->
	case lessthan({P, PId}, {S, SId}) of
		true ->
			{S, PId};
		false ->
			{P, PId}
	end.
