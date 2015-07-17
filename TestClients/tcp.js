/**
 * Created by Amershan on 2015. 07. 09..
 */
var net = require('net');
var readline = require('readline');
var  rl = readline.createInterface(process.stdin, process.stdout);
var client = new net.Socket();
var command='';

client.connect(9000, '127.0.0.1', function() {
    console.log('Connected');
    rl.setPrompt('MessageHub> ');
    rl.prompt();
});

rl.on('line', function(line) {
    var arrayOfStrings = line.split(' ');

    switch(arrayOfStrings[0]) {
        case 'help':
            console.log('Available commands: \n' +
                'connect \n' +
                'Usage: connect username password \n' +
                'if you are a new user the server automatically registers you with the username/password \n' +
                'create \n' +
                'usage: create channel \n' +
                'creates a channel \n ' +
                'subscribe \n' +
                'Usage: subscribe channel \n' +
                'subscribe to a channel, you will receive message from this channel when you are online \n' +
                'publish \n' +
                'Usage: publish channel message \n' +
                'publish the mesage to the channel, everyone whos subscribed and online will receive it \n' +
                'unsubcribe \n' +
                'Usage: subscribe channel \n' +
                'Unsubscribe from the channel \n' +
                'quit \n' +
                'Disconnects from the server and exit the app');
            break;
        case 'quit':
            client.write(line);
            process.exit(0);
            break;

        case 'connect':
             if (arrayOfStrings.length != 3) {
                 console.log("wrong usage of the command connect");
             } else {
                 client.write(arrayOfStrings[0] + ':::' + arrayOfStrings[1] + ':::' + arrayOfStrings[2]);
             }

            break;

        case 'create':
            if (arrayOfStrings.length != 2) {
                console.log("wrong usage of the command create");
            } else {
                client.write(arrayOfStrings[0] + ':::' + arrayOfStrings[1]);
            }

            break;

        case 'subscribe':
            if (arrayOfStrings.length != 2) {
                console.log("wrong usage of the command subscribe");
            } else {
                client.write(arrayOfStrings[0] + ':::' + arrayOfStrings[1]);
            }
            break;

        case 'unsubscribe':
            if (arrayOfStrings.length != 2) {
                console.log("wrong usage of the command unsubscribe");
            } else {
                client.write(arrayOfStrings[0] + ':::' + arrayOfStrings[1]);
            }
            break;

        case 'publish':
            if (arrayOfStrings.length < 3) {
                console.log("wrong usage of the command publish");
            } else {
                var cmd = arrayOfStrings[0];
                var argument = arrayOfStrings[1];
                var newArray = arrayOfStrings;
                newArray.splice(0,2);
                var message = newArray.join(' ');

                client.write(cmd + ':::' + argument + ':::' + message);
            }
            break;
        default:
            console.log('Wrong command');
            break;
    }
    rl.prompt();
}).on('close', function() {
    console.log('Have a great day!');
    process.exit(0);
});

client.on('data', function(data) {
    console.log('-> ' + data + '\n');
    //client.write('quit');
    //client.destroy(); // kill client after server's response
});

client.on('close', function() {
    console.log('Connection closed');
});
