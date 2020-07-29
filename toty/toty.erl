-module(toty).

-export([startInit/2, init/2, startProcess/4]).

init(Id, Jitter) ->
  spawn(fun() -> startInit(Id, Jitter) end).

startInit(Id, Jitter) ->
  receive 
    {start, Worker, Ms, Show} ->
      % startProcess(Worker, Ms, Jitter, Show)
      server(Worker, seq:new(Id), Ms, [], [], Jitter, Show)
  end.

startProcess(Worker, Managers, Jitter, Show) ->
  receive
    {send, Msg} ->
      lists:foreach(fun(M) -> M ! Msg end, Managers),
      startProcess(Worker, Managers, Jitter, Show);
    {Id, N} ->
      timer:sleep(random:uniform(Jitter)),
      Worker ! {Id, N, Show},
      startProcess(Worker, Managers, Jitter, Show);
    stop ->
      ok
	end.

% Worker: el proceso al cual llegan los mensajes entregados
% Next: siguiente Seq a proponer
% Managers: todos los nodos de la red
% Cast: un conjunto de referencias a los mensajes que han sido
%  enviados pero aún no se le ha asignado un número de secuencia final.
%  {Ref, <cantidad de managers>, Next} or {agreed, Ref, Seq}
% Queue: los mensajes recibidos pero aún no entregados
%  {Ref, Msg, new/agreed, Next}
% Jitter: el parámetro jitter que introduce algún delay en la red

server(Worker, Next, Managers, Cast, Queue, Jitter, Show) ->
  receive
    {send, Msg} ->
      Ref = make_ref(),
      request(Ref, Msg, Managers),
      NewCast = {Ref, length(Managers), Next},
      server(Worker, Next, Managers, [NewCast|Cast], Queue, Jitter, Show);

    {request, From, Ref, Msg} ->
      From ! {proposal, Ref, Next},
      Queue2 = [{Ref, Msg, new, Next}|Queue],
      Next2 = seq:increment(Next),
      server(Worker, Next2, Managers, Cast, Queue2, Jitter, Show);

    {proposal, Ref, Proposal} ->
      case proposal(Ref, Proposal, Cast) of
        {agreed, Seq, Cast2} ->
          agree(Ref, Seq, Managers),
          server(Worker, Next, Managers, Cast2, Queue, Jitter, Show);
        Cast2 ->
          server(Worker, Next, Managers, Cast2, Queue, Jitter, Show)
      end;

    {agreed, Ref, Seq} ->
      Updated = update(Ref, Seq, Queue),
      {Agreed, Queue2} = agreed(Updated),
      deliver(Worker, Agreed, Jitter, Show),
      Next2 = seq:maxId(Next, Seq),
      server(Worker, Next2, Managers, Cast, Queue2, Jitter, Show);

    stop ->
      ok
	end.

request(Ref, Msg, Managers) ->
	Self = self(),
	lists:foreach(
    fun(Node) ->
      Node ! {request, Self, Ref, Msg}
    end, Managers).

agree(Ref, Seq, Managers)->
	lists:foreach(fun(Pid)->
			Pid ! {agreed, Ref, Seq}
		end,
		Managers).

deliver(Worker, Messages, Jitter, Show) ->
	lists:foreach(
    fun({Id, N})->
		  timer:sleep(random:uniform(Jitter)),
      Worker ! {Id, N, Show}
		end, Messages).

% Ref es la referencia que se cree
% Proposal es el next del otro Manager
proposal(Ref, Proposal, [{Ref, 1, Sofar}|Cast])->
	{agreed, seq:max(Proposal, Sofar), Cast};

proposal(Ref, Proposal, [{Ref, N, Sofar}|Cast])->
	[{Ref, N-1, seq:max(Proposal, Sofar)}|Cast];

% Caso Ref distinto al Ref del primer elemento de la queue Cast
% sigo buscando el Ref y ordeno los entry
proposal(Ref, Proposal, [Entry|Cast])->
	case proposal(Ref, Proposal, Cast) of
		{agreed, Agreed, Rst} ->
			{agreed, Agreed, [Entry|Rst]};
		Updated ->
			[Entry|Updated]
	end.

agreed([{_Ref, Msg, agreed, _Agr}|Queue]) ->
	{Agreed, Rest} = agreed(Queue),
	{[Msg|Agreed], Rest};

agreed(Queue) ->
	{[], Queue}.

update(Ref, Agreed, [{Ref, Msg, new, _}|Queue])->
	queue(Ref, Msg, agreed, Agreed, Queue);

update(Ref, Agreed, [Entry|Queue])->
	[Entry|update(Ref, Agreed, Queue)].

queue(Ref, Msg, State, Proposal, []) ->
	[{Ref, Msg, State, Proposal}];

queue(Ref, Msg, State, Proposal, Queue) ->
	[Entry|Rest] = Queue,
	{_,_,_,Next} = Entry,
	case seq:lessthan(Proposal, Next) of
		true ->
			[{Ref, Msg, State, Proposal}|Queue];
		false ->
			[Entry|queue(Ref, Msg, State, Proposal, Rest)]
	end.
