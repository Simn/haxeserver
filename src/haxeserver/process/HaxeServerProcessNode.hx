package haxeserver.process;

import js.node.child_process.ChildProcess.ChildProcessEvent;
import haxe.io.Bytes;
import js.node.Buffer;
import js.node.stream.Readable.ReadableEvent;
import js.node.child_process.ChildProcess as ChildProcessObject;
import js.node.ChildProcess;

private class RequestCallback {
	public var next:Null<RequestCallback>;
	public final callback:HaxeServerRequestResult->Void;
	public final errback:String->Void;
	public var stdout:Buffer;

	public function new(callback:HaxeServerRequestResult->Void, errback:String->Void) {
		this.callback = callback;
		this.errback = errback;
		stdout = Buffer.alloc(0);
	}

	public function append(callback:HaxeServerRequestResult->Void, errback:String->Void) {
		next = new RequestCallback(callback, errback);
	}

	public function addStdout(buf:Buffer) {
		stdout = Buffer.concat([stdout, buf]);
	}
}

class HaxeServerProcessNode implements IHaxeServerProcess extends HaxeServerProcessBase {
	static final stdinSepBuf = Buffer.alloc(1, 1);

	var process:ChildProcessObject;
	var requests:Null<RequestCallback>;
	var response:Null<{
		length:Int,
		buffer:Buffer,
		index:Int
	}>;
	var buffer:Buffer;

	public function new(arguments:Array<String>) {
		arguments = arguments.concat(["--wait", "stdio"]);
		process = ChildProcess.spawn("haxe", arguments);
		buffer = Buffer.alloc(0);
		process.stderr.on(ReadableEvent.Data, onData);
		process.stdout.on(ReadableEvent.Data, onStdout);
		process.on(ChildProcessEvent.Exit, onExit);
	}

	public function isAsynchronous() {
		return true;
	}

	public function request(arguments:Array<String>, ?stdin:Bytes, callback:HaxeServerRequestResult->Void, errback:String->Void) {
		if (requests == null) {
			requests = new RequestCallback(callback, errback);
		} else {
			requests.append(callback, errback);
		}
		var bytes = prepareInput(arguments, stdin);
		process.stdin.write(Buffer.hxFromBytes(bytes));
	}

	public function close() {
		process.kill();
	}

	function onData(data:Buffer) {
		if (data.length == 0) {
			return;
		}
		buffer = Buffer.concat([buffer, data]);
		processBuffer();
	}

	function onStdout(data:Buffer) {
		if (requests != null) {
			requests.addStdout(data);
		}
	}

	function onExit(code:Int, msg:String) {
		while (requests != null) {
			requests.errback('Process exited with code $code: $msg');
			requests = requests.next;
		}
	}

	function processBuffer() {
		if (response == null) {
			if (buffer.length < 4) {
				return;
			}
			var length = buffer.readInt32LE(0);
			buffer = buffer.slice(4);
			response = {
				length: length,
				buffer: Buffer.alloc(length),
				index: 0
			};
		}
		var length = Std.int(Math.min(buffer.length, response.length));
		buffer.copy(response.buffer, response.index, 0, length);
		buffer = buffer.slice(length);
		response.index += length;
		if (response.index == response.length) {
			var result = processResult(response.buffer.hxToBytes(), requests.stdout.hxToBytes());
			requests.callback(result);
			requests = requests.next;
			response = null;
		}
	}
}
