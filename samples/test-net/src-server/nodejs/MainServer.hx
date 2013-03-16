package nodejs;
import logic.SessionRegistry;
import logic.Session;
import haxe.io.Bytes;
import js.Node;
import nodejs.NodeUtils;
using nodejs.NodeUtils;

class NodeSession extends Session {

    public var socket:NodeNetSocket;

    public function new(socket:NodeNetSocket) {
        super();
        this.socket = socket;
    }

    public override function close():Void {
        socket.end();
    }

    public override function writeMsg(msg:protohx.Message):Void {
        socket.writeMsg(msg);
    }
}

class MainServer {

    private static var net:NodeNet = Node.net;
    private static var console:NodeConsole = Node.console;

    public static function main() {
        flashCrossDomain();
        tcpTest();
        haxe.Timer.delay(MainBot.tcpClientTest, 1000);
        haxe.Timer.delay(MainBot.tcpClientTest, 1000);
    }

    public static function tcpTest() {
        var sr:SessionRegistry = new SessionRegistry();
        var server:NodeNetServer = net.createServer(function(client:NodeNetSocket) {
            client.on(NodeC.EVENT_STREAM_CONNECT, function() {
                var session = new NodeSession(client);
                client.setSession(session);
                sr.registerSession(session);
                console.log('server got client connection: ${client.getAP()}');
            });
//            client.on(NodeC.EVENT_STREAM_DRAIN, function() {
//                console.log('client drain: ${client.getAP()}');
//            });
            client.on(NodeC.EVENT_STREAM_ERROR, function(e) {
                console.log('server got client error: ${client.getAP()}:\n  ${e}');
            });
            client.on(NodeC.EVENT_STREAM_DATA, function(buffer:NodeBuffer) {
                var session = client.getSession();
                var bytes = buffer.toBytes();
                session.msgQueue.addBytes(bytes);
                sr.handleData(session);
            });
            client.on(NodeC.EVENT_STREAM_END, function(d) {
//                console.log('server got client end: ${client.getAP()}');
                client.end();
                sr.handleDisconnect(client.getSession());
            });
            client.on(NodeC.EVENT_STREAM_CLOSE, function() {
                console.log('server got client close: ${client.getAP()}');
            });
        });
        server.on(NodeC.EVENT_STREAM_ERROR, function(e) {
            console.log('server got server error: ${e}');
        });
        server.listen(5000, /* "localhost", */ function() {
            console.log('server bound: ${server.serverAddressPort()}');
        });
        console.log('simple server started');
    }

    public static function flashCrossDomain() {
        var server = net.createServer(function(client) {
            client.addListener(NodeC.EVENT_STREAM_CONNECT, function() {
                client.write('<?xml version="1.0"?><cross-domain-policy><allow-access-from domain="*" to-ports="*"/></cross-domain-policy>');
                client.end();
            });
            client.on(NodeC.EVENT_STREAM_ERROR, function(e) {
                console.log('client error: ${client.getAP()}:\n  ${e}');
            });
            client.on(NodeC.EVENT_STREAM_END, function(d) {
                console.log('client end: ${client.getAP()}');
                client.end();
            });
        });
        server.on(NodeC.EVENT_STREAM_ERROR, function(e) {
            console.log('server error: ${e}');
        });

//        trace("args[1] " + Node.process.argv[2]);
        server.listen(843, function() {
            console.log('flashCrossDomain server bound: ${server.serverAddressPort()}');
        });
    }
}