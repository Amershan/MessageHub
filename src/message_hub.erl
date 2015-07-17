%%%-------------------------------------------------------------------
%%% @author Amershan
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. júl. 2015 12:15
%%%-------------------------------------------------------------------
-module(message_hub).
-author("Amershan").

%% API
-compile(export_all).

-define(TcpPort, 9000).
-define(UDPPort, 4000).

start_server() ->
  Pid = spawn_link(fun() ->
    link(spawn(fun () ->
      tcp_server:start_server(?TcpPort)
      end)),
    link(spawn(fun () ->
      udp_server:start_server(?UDPPort)
      end))
  end),
  {ok, Pid},
  ets:new(users, [named_table, ordered_set, public]),
  ets:new(subscriptions, [named_table, ordered_set, public]),
  ets:new(channel,[named_table, ordered_set, public]).

register_user(Username, Password, Type, ConnectionData) ->
  UserData = ets:lookup(users, Username),

  if
    (UserData =:= []) ->
      ets:insert(users, {Username, [Password, Type, ConnectionData]});
    true ->
      [{_, [ResultPassword, _ResultType, _ConnData]}] = UserData,
      if
        (Password =:= ResultPassword) ->
          ets:insert(users, {Username, [Password, Type, ConnectionData]});
        true -> false
      end
  end.

register_channel(Channel, Owner) ->

  ets:insert_new(channel, {Channel, Owner}),
  ets:insert_new(subscriptions, {Channel, [Owner]}).

publish(Channel, Message, Publisher) ->
  Result = ets:lookup(subscriptions, Channel),
  SubscribedUsers = if
                      (Result =:= []) -> [] ;
                      true ->
                        [{_Channel, UserList}]= Result,
                        UserList
                    end,
  MessageToSend = Channel ++ " -> " ++ Publisher ++ " : " ++ Message,
  lists:foreach(fun(Elem) ->
    User = ets:lookup(users, Elem),
    if
      (User =:= []) -> [];
      true ->
        [{Username, [_Password, Type, ConnectionData]}] = User,
        if
          (Type =:= "tcp") ->
            if
              (Username =:= Publisher) -> [];
              true -> if
                        (ConnectionData =:= []) ->
                          io:format("No live tcp connection found ~n~p", [Username]);
                        true ->
                          tcp_server:sendMessage(ConnectionData, MessageToSend)
                      end
            end;
          true ->
            if
              (Username =:= Publisher) -> [];
              true ->
                if
                  (ConnectionData =:= []) ->
                    io:format("No live udp connection found for User ~n ~p", [Username]);
                  true ->
                    {Socket, CIp, CPort} = ConnectionData,
                    udp_server:sendMessage(Socket, CIp, CPort, MessageToSend)
                end

            end
        end
    end
  end, SubscribedUsers).

subscribe(Channel, User) ->
  SubscribedUsers = lists:flatten(ets:lookup(subscriptions, Channel)),
  if
    (SubscribedUsers =:= []) ->
      ets:insert_new(subscriptions, {Channel, [User]});
    true ->
      [{_Ch, Subscriptions}] = SubscribedUsers,
      NewSubscribeList = lists:append(Subscriptions, [User]),
      ets:insert(subscriptions, {Channel, NewSubscribeList})
  end,
  true.

getUserInfo(Type, ConnectionData) ->
  UserInfo =  if
                (Type =:= "tcp") ->
                  lists:flatten(ets:match(users, {'$1', ['_', '_', ConnectionData]}));
                true -> {Socket, CIp, CPort} = ConnectionData,
                  lists:flatten(ets:match(users, {'$1', ['_', '_', {Socket, CIp, CPort}]}))
              end,
  io:format("UserInfo: ~p ~n", [UserInfo]),
  UserInfo.

disconnectUser(Type, Username) ->
  UserData = lists:flatten(ets:match(users, {Username, ['$1', Type, '_']})),
%%   clear the connection data
  ets:insert(users, {Username, [UserData, Type, []]}),
  io:format("~p disconnected ~n", [Username]).

unsubscribe(Channel, Username) ->
  Subscribers = ets:lookup(subscriptions, Channel),

  if
    (Subscribers =:= []) ->
      sendMessage(Username, "Channel not found");
    true ->
      [{_, UserList}] = Subscribers,
      NewSubscribers = UserList -- [Username],
      ets:insert(subscriptions, {Channel, NewSubscribers}),
      io:format("~p", [ets:match(subscriptions, '$1')])
  end.

sendMessage(Username, Message) ->
  UserConnection = ets:match(users, {Username, ['_', '$1', '$2']}),
  if
    (UserConnection =:= []) ->
      io:format("No live connection found ~n");
    true ->
      {Type, ConnectionData} = UserConnection,
      if
        (Type =:= "tcp") ->
          tcp_server:sendMessage(ConnectionData, Message);
        true ->
          {Socket, Cip, CPort} = ConnectionData,
          udp_server:sendMessage(Socket, Cip, CPort, Message)
      end
  end.