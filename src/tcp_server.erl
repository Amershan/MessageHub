%%%-------------------------------------------------------------------
%%% @author Amershan
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. júl. 2015 16:22
%%%-------------------------------------------------------------------
-module(tcp_server).
-author("Amershan").

%% API
-export([start_server/1, sendMessage/2]).

start_server(Port) ->
  Pid = spawn_link(fun() ->
    {ok, LSocket} = gen_tcp:listen(Port, [binary, {active, false}]),
    io:format("TCP server listening on port: ~p ~n", [Port]),
    spawn(fun () -> acceptState(LSocket) end),
    timer:sleep(infinity)
  end),
  {ok, Pid}.

acceptState(LSocket) ->
  {ok, ASocket} = gen_tcp:accept(LSocket),
  spawn(fun() -> acceptState(LSocket) end),
  tcpHandler(ASocket).

tcpHandler(ASocket) ->
  inet:setopts(ASocket, [{active, once}]),

  receive
    {tcp, ASocket, <<"quit">>} ->
      User = message_hub:getUserInfo("tcp", ASocket),
      message_hub:disconnectUser("tcp", User),
      gen_tcp:close(ASocket);
    {tcp, ASocket, BinaryMsg} ->
      ReceivedData = [binary_to_list(X) || X <- binary:split(BinaryMsg, [<<":::">>], [trim, global])],
      io:format("Server received: ~p ~n", [ReceivedData]),

      case lists:member("connect", ReceivedData) of
        true  ->
          [_, UserName, Password] = ReceivedData,
          IsSuccess = message_hub:register_user(UserName, Password, "tcp", ASocket),
          if
            (IsSuccess =:= false) ->
              gen_tcp:send(ASocket, "Username Already taken or wrong authentication information");
            true ->
              gen_tcp:send(ASocket, "User successfuly connected")
          end;
        false ->  case lists:member("create", ReceivedData) of
                    true  ->
                      [_, Channel] = ReceivedData,
                      Username = message_hub:getUserInfo("tcp", ASocket),
                      if
                        (Username =:= []) ->
                          io:format("User not connected ~n");
                        true ->
                          message_hub:register_channel(Channel, Username),
                          gen_tcp:send(ASocket,  "Channel " ++ Channel ++" succesfully created")
                      end;
                    false -> case lists:member("subscribe", ReceivedData) of
                               true ->
                                 [_, Channel] = ReceivedData,
                                 Username = message_hub:getUserInfo("tcp", ASocket),
                                 if
                                   (Username =:= []) ->
                                     io:format("User not connected ~n");
                                   true ->
                                     message_hub:subscribe(Channel, Username),
                                     gen_tcp:send(ASocket,  "Succesfully subscribed to channel  " ++ Channel)
                                 end;
                               false  ->  case lists:member("publish", ReceivedData) of
                                            true  ->
                                              [_, Channel, Message] = ReceivedData,
                                              Username = message_hub:getUserInfo("tcp", ASocket),
                                              if
                                                (Username =:= []) ->
                                                  io:format("User not connected ~n");
                                                true ->
                                                  message_hub:publish(Channel, Message, Username)
                                              end;
                                            false -> case lists:member("unsubscribe", ReceivedData) of
                                                       true ->
                                                         [_, Channel] = ReceivedData,
                                                         Username = message_hub:getUserInfo("tcp", ASocket),
                                                         if
                                                           (Username =:= []) -> io:format("User not connected ~n");
                                                           true ->
                                                             message_hub:unsubscribe(Channel, Username)
                                                         end;
                                                       false ->
                                                         gen_tcp:send(ASocket, "Command not supported")
                                                    end
                                          end
                             end
                  end
      end,
      tcpHandler(ASocket)
  end.


sendMessage(Socket, Message) ->
  gen_tcp:send(Socket, Message).

