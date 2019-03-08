# Haxe Server

The haxeserver library provides an interface to communicate with Haxe compilation server instances. It comes with the following abstraction:

### Level 1: Processes

The classes in the `haxeserver.process` package manage the actual instances of the Haxe compiler. By their nature, these processes are either synchronous or asynchronous. For simplicity, even the synchronous processes provide an asynchronous request-interface where the result of a request becomes the argument of a callback.

### Level 2: `rawRequest` on HaxeServerSync and HaxeServerAsync

These classes abstract over the processes and provide easy-to-use request methods who are either synchronous or asynchronous. The asynchronous interface works with both synchronous and asynchronous processes, but he synchronous interface requires a synchronous process.

At this level, the exact arguments to the processes have to be managed manually.

### Level 3: JSON-RPC requests via `request` on HaxeServerSync and HaxeServerAsync

Through the `request` method, the methods defined in the `haxeserver.protocol` can be used to easily communicate with Haxe in a defined manner.

## Example

```haxe
class Main {
	static function main() {
		exampleSync();
		exampleAsync();
		exampleProtocol();
	}

	// The function which creates our process. In this case, we use the synchronous
	// HaxeServerProcessSys.
	static var createProcess = () -> new haxeserver.process.HaxeServerProcessSys([]);

	static function exampleSync() {
		// Create the HaxeServerSync instance. It will launch the process automatically.
		var haxeServer = new haxeserver.HaxeServerSync(createProcess);

		// Send a raw request to get the Haxe version and trace it.
		trace(haxeServer.rawRequest(["--version"]));

		// Close the server. This also stops the process.
		haxeServer.close();
	}

	static function exampleAsync() {
		// Create the HaxeServerAsync instance. It will launch the process automatically.
		var haxeServer = new haxeserver.HaxeServerAsync(createProcess);

		// Send a raw request to get the Haxe version and process it in the callback.
		haxeServer.rawRequest(["--version"], result -> {
			trace(result);
			// Close the server. This also stops the process.
			haxeServer.close();
		});
	}

	static function exampleProtocol() {
		var haxeServer = new haxeserver.HaxeServerAsync(createProcess);

		haxeServer.request(haxeserver.protocol.Protocol.Methods.Initialize, {}, result -> {
			// The compiler knows it's a haxeserver.protocol.InitializeResult
			$type(result);
			trace(result);
			haxeServer.close();
		});
	}
}
```