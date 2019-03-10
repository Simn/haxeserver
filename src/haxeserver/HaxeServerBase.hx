package haxeserver;

import haxe.Json;
import jsonrpc.Types.RequestMessage;
import haxeserver.protocol.Protocol;
import haxeserver.process.IHaxeServerProcess;

/**
	`HaxeServer` is one level above `IHaxeServerProcess` and manages communication with it.

**/
class HaxeServerBase {
	var defaultRequestArguments:Array<String>;
	var process:IHaxeServerProcess;
	var requestId:Int;
	var createProcess:Void->IHaxeServerProcess;
	var isAsynchronous:Bool;

	/**
		Creates a new `HaxeServer`, communicating with `haxeServerProcess`.
	**/
	function new(createProcess:Void->IHaxeServerProcess, isAsynchronous:Bool) {
		requestId = 0;
		defaultRequestArguments = [];
		this.createProcess = createProcess;
		this.isAsynchronous = isAsynchronous;
		start();
	}

	public function start() {
		if (process != null) {
			process.close();
		}
		process = createProcess();
		if (process.isAsynchronous() && !isAsynchronous) {
			throw 'Cannot use synchronous haxe server with asynchronous process';
		}
	}

	public function stop(graceful:Bool = true, ?callback:() -> Void) {
		if (process != null) {
			process.close(graceful, callback);
			process = null;
		}
	}

	/**
		Sets the default `arguments` that are used on every request.
	**/
	public function setDefaultRequestArguments(arguments:Array<String>) {
		this.defaultRequestArguments = arguments;
	}

	function getRequestArguments<P, R>(method:HaxeRequestMethod<P, R>, ?params:P):Array<String> {
		var id = requestId++;
		var request:RequestMessage = {
			jsonrpc: @:privateAccess jsonrpc.Protocol.PROTOCOL_VERSION,
			id: id,
			method: method
		}
		if (params != null) {
			request.params = params;
		}
		var requestJson = Json.stringify(request);
		var arguments = ["--display", requestJson];
		return arguments;
	}

	/**
		Closes the `HaxeServer` instance and the underlying process.
	**/
	public function close() {
		process.close();
	}
}
