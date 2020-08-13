package haxeserver.process;

import js.node.child_process.ChildProcess.ChildProcessEvent;
import haxe.io.Bytes;
import js.node.Buffer;
import js.node.stream.Readable.ReadableEvent;
import js.node.child_process.ChildProcess as ChildProcessObject;
import js.node.ChildProcess;

private class RequestCallback {
	public final callback:HaxeServerRequestResult->Void;
	public final errback:String->Void;
	public final stdin:Bytes;
	public var active:Bool;
	public var next:Null<RequestCallback>;

	public function new(stdin:Bytes, callback:HaxeServerRequestResult->Void, errback:String->Void) {
		this.stdin = stdin;
		this.callback = callback;
		this.errback = errback;
		active = false;
	}

	public function append(requestCallback:RequestCallback) {
		if (next == null) {
			next = requestCallback;
		} else {
			next.append(requestCallback);
		}
	}

	public function setActive() {
		active = true;
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
	var stderrBuffer:Buffer;
	var stdoutBuffer:Buffer;
	var closeRequested:Bool;
	var onCloseCallbacks:Array<() -> Void>;
	var onExitCallbacks:Array<String->Void>;

	public function new(command:String, arguments:Array<String>, ?options:ChildProcessSpawnOptions) {
		arguments = arguments.concat(["--wait", "stdio"]);
		reset();
		process = ChildProcess.spawn(command, arguments, options);
		process.stderr.on(ReadableEvent.Data, handleOnStderr);
		process.stdout.on(ReadableEvent.Data, handleOnStdout);
		process.on(ChildProcessEvent.Exit, handleOnExit);
	}

	public function isAsynchronous() {
		return true;
	}

	public function request(arguments:Array<String>, ?stdin:Bytes, callback:HaxeServerRequestResult->Void, errback:String->Void) {
		var bytes = prepareInput(arguments, stdin);
		var request = new RequestCallback(bytes, callback, errback);
		if (requests == null) {
			requests = request;
		} else {
			requests.append(request);
		}
		checkRequestQueue();
	}

	/**
		Registers `callback` to be called when the Haxe process exits. It receives
		the content of stderr as argument.
	**/
	public function onExit(callback:String->Void) {
		onExitCallbacks.push(callback);
	}

	/**
		Closes the Haxe compilation server process. No other methods on `this`
		instance should be used afterwards.

		If `graceful` is `true` and there is a request which has already been sent
		to the Haxe process, that request is allowed to finish before closing
		the process.

		If `graceful` is `false`, the process is closed (killed) immediately.

		In either case, if `callback` is provided, it is called after the process
		has terminated.
	**/
	public function close(graceful:Bool = true, ?callback:() -> Void) {
		if (callback != null) {
			onCloseCallbacks.push(callback);
		}
		if (graceful && requests != null && requests.active) {
			closeRequested = true;
		} else {
			reset();
		}
	}

	function reset() {
		while (requests != null) {
			requests.errback('Process closed');
			requests = requests.next;
		}
		if (onCloseCallbacks != null) {
			for (callback in onCloseCallbacks) {
				callback();
			}
		}
		if (process != null) {
			process.removeAllListeners();
			process.kill();
			process = null;
		}
		onCloseCallbacks = [];
		onExitCallbacks = [];
		stderrBuffer = Buffer.alloc(0);
		stdoutBuffer = Buffer.alloc(0);
		closeRequested = false;
	}

	function checkRequestQueue() {
		if (closeRequested) {
			reset();
			return;
		}
		if (requests != null && !requests.active) {
			requests.setActive();
			process.stdin.write(Buffer.hxFromBytes(requests.stdin));
		}
	}

	function handleOnStderr(data:Buffer) {
		if (data.length == 0) {
			return;
		}
		stderrBuffer = Buffer.concat([stderrBuffer, data]);
		processBuffer();
	}

	function handleOnStdout(data:Buffer) {
		if (requests != null) {
			stdoutBuffer = Buffer.concat([stdoutBuffer, data]);
		}
	}

	function handleOnExit(code:Int, msg:String) {
		while (requests != null) {
			requests.errback('Process exited with code $code: $msg');
			requests = requests.next;
		}
		var stderr = stderrBuffer.toString();
		for (callback in onExitCallbacks) {
			callback(stderr);
		}
	}

	function processBuffer() {
		if (response == null) {
			if (stderrBuffer.length < 4) {
				return;
			}
			var length = stderrBuffer.readInt32LE(0);
			stderrBuffer = stderrBuffer.slice(4);
			response = {
				length: length,
				buffer: Buffer.alloc(length),
				index: 0
			};
		}
		var length = Std.int(Math.min(stderrBuffer.length, response.length - response.index));
		stderrBuffer.copy(response.buffer, response.index, 0, length);
		stderrBuffer = stderrBuffer.slice(length);
		response.index += length;
		if (response.index == response.length) {
			while (process.stdout.readable) {
				var read = process.stdout.read();
				if (read == null) {
					break;
				}
				handleOnStdout(read);
			}
			var result = processResult(response.buffer.hxToBytes(), stdoutBuffer.hxToBytes());
			stdoutBuffer = Buffer.alloc(0);
			requests.callback(result);
			requests = requests.next;
			response = null;
			checkRequestQueue();
		}
	}
}
