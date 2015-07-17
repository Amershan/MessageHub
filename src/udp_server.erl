%%%-------------------------------------------------------------------
%%% @author Amershan
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. júl. 2015 16:23
%%%-------------------------------------------------------------------
-module(udp_server).
-author("Amershan").

%% API
-export([start_server/1, sendMessage/4]).

start_server(Port) ->
  Pid = spawn_link(fun() ->
    {ok, Socket} = gen_udp:open(Port, [binary, {active, true}]),
    io:format("Udp server listening on port: ~p~n",[Port]),
    udpHandler(Socket)
  end),
  {ok, Pid}.


udpHandler(Socket) ->
  inet:setopts(Socket, [{active, once}]),
  receive
    {udp, Socket, CIp, CPort, <<"quit">>} ->
      User = message_hub:getUserInfo("udp", {Socket, CIp, CPort}),
      message_hub:disconnectUser("udp", User),
      gen_udp:close(Socket);
    {udp, Socket, CIp, CPort, BinaryMsg} ->
      io:format("UDP server received: ~p~n",[BinaryMsg]),
      ReceivedData = [binary_to_list(X) || X <- binary:split(BinaryMsg, [<<":::">>], [trim, global])],
      case lists:member("connect", ReceivedData) of
        true  ->
          [_, UserName, Password] = ReceivedData,
          IsSuccess = message_hub:register_user(UserName, Password, "udp", {Socket, CIp, CPort}),
          if
            (IsSuccess =:= false) ->
              gen_udp:send(Socket, CIp, CPort, "Username Already taken or wrong authentication information");
            true ->
              gen_udp:send(Socket, CIp, CPort, "User successfuly connected")
          end,
          udpHandler(Socket);
        false ->  case lists:member("create", ReceivedData) of
                    true  ->
                      [_, Channel] = ReceivedData,
                      Username = message_hub:getUserInfo("udp", {Socket, CIp, CPort}),
                      if
                        (Username =:= []) -> io:format("User not connected");
                        true ->
                          message_hub:register_channel(Channel, Username),
                          gen_udp:send(Socket, CIp, CPort,  "Channel " ++ Channel ++" succesfully created")
                      end;
                    false -> case lists:member("subscribe", ReceivedData) of
                               true ->
                                 [_, Channel] = ReceivedData,
                                 Username = message_hub:getUserInfo("udp", {Socket, CIp, CPort}),
                                 if
                                   (Username =:= []) ->
                                     io:format("User not connected");
                                   true ->
                                     message_hub:subscribe(Channel, Username),
                                     io:format("Succesfully subscribed to channel ~p~n", [Channel])
                                 end;
                               false  ->  case lists:member("publish", ReceivedData) of
                                            true  ->
                                              [_, Channel, Message] = ReceivedData,
                                              Username = message_hub:getUserInfo("udp", {Socket, CIp, CPort}),
                                              message_hub:publish(Channel, Message, Username);
                                            false -> case lists:member("unsubscribe", ReceivedData) of
                                                       true ->
                                                         [_, Channel] = ReceivedData,
                                                         Username = message_hub:getUserInfo("udp", {Socket, CIp, CPort}),
                                                         if
                                                           (Username =:= []) -> io:format("User not connected");
                                                           true ->
                                                             message_hub:unsubscribe(Channel, Username),
                                                             io:format("Succesfuly unsubscribed from channel ~p~n", [Channel])
                                                         end;
                                                       false ->
                                                         gen_udp:send(Socket, CIp, CPort, "Command not supported")
                                                     end
                                          end
                             end
                  end
      end,
      udpHandler(Socket)
  end.

sendMessage(Socket, CIp, CPort, Message) ->
  gen_udp:send(Socket, CIp, CPort, Message).

