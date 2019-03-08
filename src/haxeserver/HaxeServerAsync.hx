package haxeserver;

import haxe.Json;
import haxe.io.Bytes;
import haxeserver.protocol.Protocol;
import haxeserver.process.IHaxeServerProcess;

/**
	`HaxeServerAsync` is one level above `IHaxeServerProcess` and manages communication with it.

	Its request methods accept a `callback` argument that is called upon completing the request. This
	works with bost synchronous and asynchronous processes.

**/
class HaxeServerAsync extends HaxeServerBase {
	/**
		Creates a new `HaxeServerAsync` which executes `createProcess` upon starting.

		Starts automatically.
	**/
	public function new(createProcess:Void->IHaxeServerProcess) {
		super(createProcess, true);
	}

	/**
		Sends a raw request to the process, using the provided `arguments` and calls `callback` upon completion.

		If `stdin` is not `null`, it is passed to the process and the argument list
		is expanded by `-D display-stdin`.
	**/
	public function rawRequest(arguments:Array<String>, ?stdin:Bytes, callback:HaxeServerRequestResult->Void) {
		arguments = defaultRequestArguments.concat(arguments);
		if (stdin != null) {
			arguments = arguments.concat(["-D", "display-stdin"]);
		}
		process.request(arguments, stdin, callback);
	}

	/**
		Sends a json-rpc request to the process, with the given `method` and `params` and calls `callback` upon completion.
	**/
	public function request<P, R>(method:HaxeRequestMethod<P, R>, ?params:P, callback:R->Void) {
		var arguments = getRequestArguments(method, params);
		function rawCallback(result) {
			callback(Json.parse(result.stderr));
		}
		rawRequest(arguments, null, rawCallback);
	}

	/**
		Convenience function to launch a new `HaxeServerAsync` instance with the given `arguments`.

		Uses `HaxeServerProcessSys` on `sys` targets and `HaxeServerProcessNode` if `nodejs` is available.

		Fails in other situations.
	**/
	static public function launch(arguments:Array<String>) {
		#if nodejs
		var f = () -> new haxeserver.process.HaxeServerProcessNode(arguments);
		#elseif sys
		var f = () -> new haxeserver.process.HaxeServerProcessSys(arguments);
		#else
		throw "No haxeserver.process class available on this target";
		#end
		return new HaxeServerAsync(f);
	}
}