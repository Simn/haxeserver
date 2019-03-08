import haxeserver.protocol.Protocol;

typedef HaxeServerProcess = #if js haxeserver.process.HaxeServerProcessNode #else haxeserver.process.HaxeServerProcessSys #end;
typedef HaxeServer = haxeserver.HaxeServerAsync;

class Main {
	static function main() {
		var process = new HaxeServerProcess([]);
		var createProcess = () -> process;
		var haxeServerAsync = new haxeserver.HaxeServerAsync(createProcess);
		var haxeServerSync = new haxeserver.HaxeServerSync(createProcess);

		var defaultArgs = ["-cp", "tests", "-cp", "src", "-lib", "json-rpc"];
		haxeServerAsync.setDefaultRequestArguments(defaultArgs);
		haxeServerSync.setDefaultRequestArguments(defaultArgs);

		trace(haxeServerSync.request(Methods.Initialize, {}));

		haxeServerAsync.request(Methods.Initialize, {}, e -> {
			trace(e);
			haxeServerAsync.close();
		});
	}
}
