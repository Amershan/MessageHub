/**
 * Created by Amershan on 2015. 07. 10..
 */
var PORT = 4000;
var HOST = '127.0.0.1';

var dgram = require('dgram');
var readline = require('readline');
var  rl = readline.createInterface(process.stdin, process.stdout);

var message = '';
var client = dgram.createSocket('udp4');

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
            message = new Buffer("quit");
            sendMessage(message);
            process.exit(0);
            break;

        case 'connect':
            if (arrayOfStrings.length != 3) {
                console.log("wrong usage of the command connect");
            } else {
                message = new Buffer(arrayOfStrings[0] + ':::' + arrayOfStrings[1] + ':::' + arrayOfStrings[2]);
                sendMessage(message);
            }

            break;

        case 'create':
            if (arrayOfStrings.length != 2) {
                console.log("wrong usage of the command create");
            } else {
                message = new Buffer(arrayOfStrings[0] + ':::' + arrayOfStrings[1]);
                sendMessage(message);
            }

            break;

        case 'subscribe':
            if (arrayOfStrings.length != 2) {
                console.log("wrong usage of the command subscribe");
            } else {
                message = new Buffer(arrayOfStrings[0] + ':::' + arrayOfStrings[1]);
                sendMessage(message);
            }
            break;

        case 'unsubscribe':
            if (arrayOfStrings.length != 2) {
                console.log("wrong usage of the command unsubscribe");
            } else {
                message = new Buffer(arrayOfStrings[0] + ':::' + arrayOfStrings[1]);
                sendMessage(message);
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
                var text = newArray.join(' ');

                message = new Buffer(cmd + ':::' + argument + ':::' + text);
                sendMessage(message);
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

var sendMessage = function(message) {
    client.send(message, 0, message.length, PORT, HOST, function(err, bytes) {
        if (err) throw err;
        console.log('UDP message sent to ' + HOST +':'+ PORT);

    });

}

client.on('message', function (data) {
    console.log(data.toString() + "\n");

});
