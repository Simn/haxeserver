package haxeserver.sync;

import haxe.Json;
import jsonrpc.Types.RequestMessage;
import haxe.io.Bytes;
import haxeserver.protocol.Protocol;

using StringTools;

class HaxeRequestException<P, R> {
	final method:HaxeRequestMethod<P, R>;
	final params:P;
	final error:String;

	public function new(error:String, method:HaxeRequestMethod<P, R>, params:Null<P>) {
		this.error = error.trim();
		this.method = method;
		this.params = params;
	}

	public function toString() {
		return 'HaxeRequestException($error, $method, $params)';
	}
}

/**
	`HaxeServer` is one level above `IHaxeServerProcess` and manages communication with it.

**/
class HaxeServer {
	var defaultRequestArguments:Array<String>;
	var process:IHaxeServerProcess;
	var requestId:Int;

	/**
		Creates a new `HaxeServer`, communicating with `haxeServerProcess`.
	**/
	public function new(haxeServerProcess:IHaxeServerProcess) {
		requestId = 0;
		defaultRequestArguments = [];
		this.process = haxeServerProcess;
	}

	/**
		Sets the default `arguments` that are used on every request.
	**/
	public function setDefaultRequestArguments(arguments:Array<String>) {
		this.defaultRequestArguments = arguments;
	}

	/**
		Sends a raw request to the process, using the provided `arguments`.

		If `stdin` is not `null`, it is passed to the process and the argument list
		is expanded by `-D display-stdin`.
	**/
	public function rawRequest(arguments:Array<String>, ?stdin:Bytes) {
		arguments = defaultRequestArguments.concat(arguments);
		if (stdin != null) {
			arguments = arguments.concat(["-D", "display-stdin"]);
		}
		return process.request(arguments, stdin);
	}

	/**
		Sends a json-rpc request to the process, with the given `method` and `params`.

		If the request fails, an exception of type `HaxeRequestException` is thrown.
	**/
	public function request<P, R>(method:HaxeRequestMethod<P, R>, ?params:P):Response<R> {
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
		var result = rawRequest(arguments);
		if (result.hasError) {
			throw new HaxeRequestException(result.stderr, method, params);
		} else {
			return Json.parse(result.stderr);
		}
	}

	/**
		Closes the `HaxeServer` instance and the underlying process.
	**/
	public function close() {
		process.close();
	}

	#if sys
	static public function launch(arguments:Array<String>) {
		var process = new HaxeServerProcess([]);
		return new HaxeServer(process);
	}
	#end
}
