package haxeserver.process;

import haxe.io.BytesBuffer;
import asys.net.Socket;
import asys.Net;
import asys.net.Server;
import eval.vm.NativeThread;
import haxe.ds.GenericStack;
import haxe.io.Bytes;
import asys.Process;

#if !target.asys
#error "HaxeServerProcess is only supported on asys targets"
#end
private class RequestCallback {
	public final callback:HaxeServerRequestResult->Void;
	public final errback:String->Void;
	public final stdin:Bytes;
	public final arguments:Array<String>;

	public function new(stdin:Bytes, callback:HaxeServerRequestResult->Void, errback:String->Void, arguments:Array<String>) {
		this.stdin = stdin;
		this.callback = callback;
		this.errback = errback;
		this.arguments = arguments;
	}
}

/**
	`HaxeServerProcess` manages the actual haxe server process. It is the
	lowest level of the architecture and only knows how to communicate with
	the haxe compilation server.
**/
class HaxeServerProcessAsys implements IHaxeServerProcess extends HaxeServerProcessBase {
	var process:Process;
	var requests:Array<RequestCallback>;
	var server:Server;
	var client:Socket;
	var response:Null<{
		length:Int,
		buffer:Bytes,
		index:Int
	}>;
	var buffer:Bytes;

	/**
		Starts a new Haxe process with the given `arguments`. It automatically
		adds `--wait stdio` to the arguments in order to set the Haxe process
		to server mode.
	**/
	public function new(command:String, arguments:Array<String>, ?cb:Void->Void) {
		function onConnect(socket:Socket) {
			client = socket;
			client.dataSignal.on(handleData);
			if (cb != null) {
				cb();
			}
		};
		server = Net.createServer({});
		server.listeningSignal.on(() -> {
			switch (server.localAddress) {
				case Network(_, port):
					arguments = arguments.concat(["--server-connect", "127.0.0.1:" + port]);
					process = Process.spawn(command, arguments);
					process.stdout.dataSignal.on(bytes -> {});
					for (pipe in process.stdio) {
						pipe.unref();
					}
					process.unref();
				case _:
					throw "Something went wrong";
			}
		});
		server.listenTcp({host: "127.0.0.1"}, onConnect);
		server.unref();

		requests = [];
		buffer = Bytes.alloc(0);
	}

	public function isAsynchronous() {
		return true;
	}

	/**
		Makes a request to the Haxe compilation server with the given `arguments`.

		If `stdin` is no `null`, it is passed to the compilation server as part
		of the request.
	**/
	public function request(arguments:Array<String>, ?stdin:Bytes, callback:HaxeServerRequestResult->Void, errback:String->Void) {
		var bytes = prepareInput(arguments, stdin);
		requests.push(new RequestCallback(stdin, callback, errback, arguments));
		client.write(bytes);
	}

	/**
		Closes the Haxe compilation server process. No other methods on `this`
		instance should be used afterwards.

		The `graceful` argument has no effect on this kind of process. If
		`callback` is given, it is called immediately after closing the process.
	**/
	public function close(graceful:Bool = true, ?callback:() -> Void) {
		if (client != null) {
			client.destroy();
		}
		server.close();
		process.close(_ -> {
			if (callback != null) {
				callback();
			}
		});
	}

	function handleData(bytes:Bytes) {
		if (bytes.length == 0) {
			return;
		}
		var newBuffer = Bytes.alloc(buffer.length + bytes.length);
		newBuffer.blit(0, buffer, 0, buffer.length);
		newBuffer.blit(buffer.length, bytes, 0, bytes.length);
		buffer = newBuffer;

		checkBuffer();
	}

	function checkBuffer() {
		function sliceBuffer(i:Int) {
			var newBuffer = Bytes.alloc(buffer.length - i);
			newBuffer.blit(0, buffer, i, buffer.length - i);
			buffer = newBuffer;
		}

		if (response == null) {
			if (buffer.length < 4) {
				return;
			}
			var length = buffer.getInt32(0);
			sliceBuffer(4);
			response = {
				length: length,
				buffer: Bytes.alloc(length),
				index: 0
			}
		}
		var length = Std.int(Math.min(buffer.length, response.length - response.index));
		response.buffer.blit(response.index, buffer, 0, length);
		sliceBuffer(length);
		response.index += length;
		if (response.index == response.length) {
			var result = processResult(response.buffer, Bytes.alloc(0));
			response = null;
			var cb = requests.shift();
			cb.callback(result);
			checkBuffer();
		}
	}
}
