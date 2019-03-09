package haxeserver.process;

import haxe.io.Bytes;
import sys.io.Process;

#if !sys
#error "HaxeServerProcess is only supported on sys targets"
#end

/**
	`HaxeServerProcess` manages the actual haxe server process. It is the
	lowest level of the architecture and only knows how to communicate with
	the haxe compilation server.
**/
class HaxeServerProcessSys implements IHaxeServerProcess extends HaxeServerProcessBase {
	var process:Process;

	/**
		Starts a new Haxe process with the given `arguments`. It automatically
		adds `--wait stdio` to the arguments in order to set the Haxe process
		to server mode.
	**/
	public function new(command:String, arguments:Array<String>) {
		arguments = arguments.concat(["--wait", "stdio"]);
		process = new Process(command, arguments);
	}

	public function isAsynchronous() {
		return false;
	}

	/**
		Makes a request to the Haxe compilation server with the given `arguments`.

		If `stdin` is no `null`, it is passed to the compilation server as part
		of the request.
	**/
	public function request(arguments:Array<String>, ?stdin:Bytes, callback:HaxeServerRequestResult->Void, errback:String->Void) {
		var bytes = prepareInput(arguments, stdin);
		process.stdin.write(bytes);
		var read = process.stderr.read(process.stderr.readInt32());
		callback(processResult(read, Bytes.alloc(0)));
	}

	/**
		Closes the Haxe compilation server process. No other methods on `this`
		instance should be used afterwards.
	**/
	public function close() {
		process.close();
	}
}
