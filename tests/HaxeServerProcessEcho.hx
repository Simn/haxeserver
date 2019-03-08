import haxeserver.process.IHaxeServerProcess;
import haxeserver.HaxeServerRequestResult;
import haxe.io.Bytes;

class HaxeServerProcessEcho implements IHaxeServerProcess {
	public function new() {}

	public function isAsynchronous() {
		return false;
	}

	public function request(arguments:Array<String>, ?stdin:Bytes, callback:HaxeServerRequestResult->Void) {
		callback({
			hasError: false,
			stdout: stdin == null ? "" : stdin.getString(0, stdin.length),
			stderr: arguments.join(" "),
			prints: []
		});
	}

	public function close() {}
}
