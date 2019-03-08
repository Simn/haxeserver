import haxeserver.process.IHaxeServerProcess;
import haxeserver.HaxeServerRequestResult;
import haxe.io.Bytes;

class HaxeServerProcessError implements IHaxeServerProcess {
	public function new() {}

	public function isAsynchronous() {
		return false;
	}

	public function request(arguments:Array<String>, ?stdin:Bytes, callback:HaxeServerRequestResult->Void, errback:String->Void) {
		errback(arguments.join(" "));
	}

	public function close() {}
}
