package haxeserver;

import haxe.io.Bytes;
import haxeserver.process.IHaxeServerProcess;

/**
	`HaxeServer` is one level above `IHaxeServerProcess` and manages communication with it.

**/
class HaxeServerSync extends HaxeServerBase {
	/**
		Creates a new `HaxeServerSync` which executes `createProcess` upon starting.

		Starts automatically.
	**/
	public function new(createProcess:Void->IHaxeServerProcess) {
		super(createProcess, false);
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
		var result = null;
		process.request(arguments, stdin, returnedResult -> result = returnedResult, err -> throw err);
		return result;
	}

	#if sys
	static public function launch(command:String, arguments:Array<String>) {
		var f = () -> new haxeserver.process.HaxeServerProcessSys(command, arguments);
		return new HaxeServerSync(f);
	}

	/**
		Makes requests via `<command> --connect <port>`.
		The haxe server process has to be started manually prior to executing requests.
	**/
	static public function connect(command:String, port:Int, arguments:Array<String>) {
		var f = () -> new haxeserver.process.HaxeServerProcessConnect(command, port, arguments);
		return new HaxeServerSync(f);
	}
	#end
}
