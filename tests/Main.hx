import haxeserver.sync.HaxeServerProcess;

class Main {
	static function main() {
		var process = new HaxeServerProcess([]);
		var haxeServer = new haxeserver.sync.HaxeServer(process);
		haxeServer.setDefaultRequestArguments(["-cp", "src"]);
		var api = new haxeserver.sync.HaxeMethods(haxeServer);
		trace(api.protocol.initialize({}));
		trace(api.server.readClassPaths());
		trace(api.display.hover({
			file: "tests/Main.hx",
			offset: 163
		}));
		haxeServer.close();
	}
}
