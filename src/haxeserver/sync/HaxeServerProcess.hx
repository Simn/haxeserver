package haxeserver.sync;

import haxe.io.BytesBuffer;
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
class HaxeServerProcess implements IHaxeServerProcess {
	var process:Process;

	/**
		Starts a new Haxe process with the given `arguments`. It automatically
		adds `--wait stdio` to the arguments in order to set the Haxe process
		to server mode.
	**/
	public function new(arguments:Array<String>) {
		arguments = arguments.concat(["--wait", "stdio"]);
		process = new Process("haxe", arguments);
	}

	/**
		Makes a request to the Haxe compilation server with the given `arguments`.

		If `stdin` is no `null`, it is passed to the compilation server as part
		of the request.
	**/
	public function request(arguments:Array<String>, ?stdin:Bytes) {
		var bytes = prepareInput(arguments, stdin);
		process.stdin.writeInt32(bytes.length);
		process.stdin.write(bytes);
		var read = process.stderr.read(process.stderr.readInt32());
		return processResult(read);
	}

	/**
		Closes the Haxe compilation server process. No other methods on `this`
		instance should be used afterwards.
	**/
	public function close() {
		process.close();
	}

	function prepareInput(arguments:Array<String>, ?stdin:Bytes) {
		var buf = new BytesBuffer();
		buf.addString(arguments.join("\n"));
		if (stdin != null) {
			buf.addByte(1);
			buf.add(stdin);
		}
		return buf.getBytes();
	}

	function processResult(result:Bytes) {
		var buf = new StringBuf();
		var currentLine = new StringBuf();
		var prints = [];
		var newLine = true;
		var hasError = false;
		var inPrint = false;
		function commitLine() {
			var line = currentLine.toString();
			if (inPrint) {
				prints.push(line);
				inPrint = false;
			} else {
				buf.add(line);
			}
			currentLine = new StringBuf();
		}
		inline function add(byte:Int) {
			currentLine.addChar(byte);
		}
		for (offset in 0...result.length) {
			var byte = result.get(offset);
			switch (byte) {
				case "\n".code:
					add(byte);
					commitLine();
					newLine = true;
				case 0x01:
					inPrint = true;
				case 0x02:
					hasError = true;
				case _:
					add(byte);
			}
		}
		commitLine();
		return {
			hasError: hasError,
			prints: prints,
			stderr: buf.toString()
		}
	}
}
