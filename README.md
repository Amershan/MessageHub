# MessageHub
In-memory MessageHub with support publish, subscribe, unsubscribe, create channel


#Install
```sh
$ git clone [git-repo-url]
$ cd MessageHub/src
$ erl --compile *.erl 
$ in erl terminal issue the following:
$ message_hub:start_server().
```
- Tcp server port: 9000
- Udp server port: 4000

# Test clients
There are node test clients in the repo.

#usage
```sh
$ cd MessageHub/TestClients
$ node tcp
```
in a nother terminal 
```sh
$ cd MessageHub/TestClients
$ node udp
```
#Test client commands:
- connect

 Usage: connect username password  

- create

 Usage: create channel

- subscribe

 Usage: subscribe channel

- publish

 Usage: publish channel message

- unsubcribe

 Usage: subscribe channel

- quit

 Usage: quit

#Note
If you are using your own client the server expects the commands in the following form:
command:::argument1:::argumentN

