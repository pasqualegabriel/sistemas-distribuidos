-module(icy).
-export([send_request/3, sender/1, send_reply/2, header_to_list/1, send_data/2, send_meta/2, request/1, reply/1]).
sender(Bin) -> Bin.
send_request(Host, Feed, Sender) ->
  Request = "GET " ++ Feed ++ " HTTP/1.0\r\n" ++
    "Host: " ++ Host ++ ":9288\r\n" ++
    "User-Agent: Ecast\r\n" ++
    "Icy-MetaData: 1\r\n" ++ "\r\n",
  Sender(list_to_binary(Request)).

send_reply(Header, Sender) ->
  Status = "ICY 200 OK\r\n",
  Reply = Status ++ header_to_list(Header),
  io:format("icy:- voy a enviar esto como reply: ~s~n FIN DE REPLY ~n",[Reply]),
  Sender(list_to_binary(Reply)).

header_to_list([]) ->
  "\r\n";
header_to_list([{Name, Arg} | Rest]) ->
  Name ++ ":" ++ Arg ++ "\r\n" ++ header_to_list(Rest).

send_data({Audio, Meta}, Sender) ->
  send_audio(Audio, Sender),
  send_meta(Meta, Sender).

send_audio(Audio, Sender) ->
  Sender(Audio).

send_meta(Meta, Sender) ->
  {K, Padded} = padding(Meta),
  Sender(<<K/integer, Padded/binary>>).

padding(Meta) ->
  K = length(Meta) div 16 + 1,
  Padding = length(Meta) rem 16,
  {K, list_to_binary(padded(Meta, K, Padding))}.

padded(Meta, 1, Padding) ->
  Meta ++ lists:duplicate(Padding, "0");

padded(Meta, K, Padding) ->
  {Xs, Ys} = lists:split(16, Meta),
  Xs ++ padded(Ys, K - 1, Padding).

request(Bin) ->
  case line(Bin) of
    {ok, "GET / HTTP/1.1", R1} ->
      case header(R1, []) of
        {ok, Header, R2} ->
          {ok, Header, R2};
        more ->
          {more, fun(More) -> request(<<Bin/binary, More/binary>>) end}
      end;
    {ok, Req, _} ->
      {error, "invalid request: " ++ Req};
    more ->
      {more, fun(More) -> request(<<Bin/binary, More/binary>>) end}
  end.

line(Bin) ->
  line(Bin, <<>>).
line(<<>>, _) ->
  more;
line(<<13, 10, Rest/binary>>, Sofar) ->
  {ok, lists:reverse(binary_to_list(Sofar)), Rest};
line(<<X, Rest/binary>>, Sofar) ->
  line(<<Rest/binary>>, <<X, Sofar/binary>>).

header(Bin, List) ->
  header(Bin, List, <<>>).

header(<<>>, _, _) ->
  more;
header(<<13, 10, 13, 10, Rest/binary>>, List, Sofar) ->
  H = lists:reverse(binary_to_list(Sofar)),
  [A,B] = lists:map(fun(E) -> binary_to_list(E) end, re:split(H,":")),
  {ok, List ++ [{A, B}], Rest};
header(<<13, 10, Rest/binary>>, List, Sofar) ->
  H = lists:reverse(binary_to_list(Sofar)),
  [A,B | LL] = lists:map(fun(E) -> binary_to_list(E) end, re:split(H,":")),
  header(Rest, List ++ [{A,B ++ LL}], <<>>);
header(<<X, Rest/binary>>, List, Sofar) ->
  header(Rest, List, <<X, Sofar/binary>>).

reply(Bin) ->
  case line(Bin) of
    {ok, "HTTP/1.0 200 OK", R1} ->
      case header(R1, []) of
        {ok, Header, R2} ->
          MetaInt = metaint(Header),
          {ok, fun() -> data(R2, MetaInt) end, Header};
        more ->
          {more, fun(More) -> reply(<<Bin/binary, More/binary>>) end}
      end;
    {ok, Resp, _} ->
      {error, "invalid reply: " ++ Resp};
    more ->
      {more, fun(More) -> reply(<<Bin/binary, More/binary>>) end}
  end.



metaint([{"icy-metaint", Value} | _]) ->
  {N, _} = string:to_integer(Value),
  N;
metaint([_ | Xs]) ->
  metaint(Xs).


data(Bin, M) ->
  audio(Bin, [], M, M).
audio(Bin, Sofar, N, M) ->
  Size = size(Bin),
  if
    Size >= N ->
      {Chunk, Rest} = split_binary(Bin, N),
      meta(Rest, lists:reverse([Chunk | Sofar]), M);
    true ->
      {more, fun(More) -> audio(More, [Bin | Sofar], N - Size, M) end}
  end.

meta(<<>>, Audio, M) ->
  {more, fun(More) -> meta(More, Audio, M) end};
meta(Bin, Audio, M) ->
  <<K/integer, R0/binary>> = Bin,
  Size = size(R0),
  H = K * 16,
  if
    Size >= H ->
      {Padded, R2} = split_binary(R0, H),
      Meta = [C || C <- binary_to_list(Padded), C > 0],
      {ok, {Audio, Meta}, fun() -> data(R2, M) end};
    true ->
      {more, fun(More) -> meta(<<Bin/binary, More/binary>>, Audio, M) end}
  end.