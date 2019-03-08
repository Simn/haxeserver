import utest.ITest;
import haxe.io.Bytes;
import utest.Assert;
import haxeserver.HaxeServerSync;
import haxeserver.HaxeServerAsync;
import haxeserver.process.IHaxeServerProcess;
import utest.Runner;
import utest.ui.Report;

class TestSyncInterface implements ITest {
	var process:IHaxeServerProcess;
	var haxeServer:HaxeServerSync;

	public function new() {}

	function setup() {
		process = new HaxeServerProcessEcho();
		haxeServer = new HaxeServerSync(() -> process);
	}

	function teardown() {
		haxeServer.close();
	}

	public function testArgs() {
		var args = ["-cp", "src", "--display", "{ \"method\": \"test\" }"];
		var result = haxeServer.rawRequest(args);
		Assert.isFalse(result.hasError);
		Assert.equals(args.join(" "), result.stderr);
	}

	public function testStdin() {
		var args = [];
		var stdin = "echo me";
		var result = haxeServer.rawRequest(args, Bytes.ofString(stdin));
		Assert.isFalse(result.hasError);
		Assert.equals(stdin, result.stdout);
	}
}

class TestAsyncInterface implements ITest {
	var process:IHaxeServerProcess;
	var haxeServer:HaxeServerAsync;

	public function new() {}

	function setup() {
		process = new HaxeServerProcessEcho();
		haxeServer = new HaxeServerAsync(() -> process);
	}

	function teardown() {
		haxeServer.close();
	}

	public function testArgs() {
		var args = ["-cp", "src", "--display", "{ \"method\": \"test\" }"];
		haxeServer.rawRequest(args, result -> {
			Assert.isFalse(result.hasError);
			Assert.equals(args.join(" "), result.stderr);
		}, msg -> Assert.fail(msg));
	}

	public function testStdin() {
		var args = [];
		var stdin = "echo me";
		haxeServer.rawRequest(args, Bytes.ofString(stdin), result -> {
			Assert.isFalse(result.hasError);
			Assert.equals(stdin, result.stdout);
		}, msg -> Assert.fail(msg));
	}
}

class TestAsyncError implements ITest {
	var process:IHaxeServerProcess;
	var haxeServer:HaxeServerAsync;

	public function new() {}

	function teardown() {
		haxeServer.close();
	}

	public function testError() {
		process = new HaxeServerProcessError();
		haxeServer = new HaxeServerAsync(() -> process);
		var args = ["-cp", "src"];
		haxeServer.rawRequest(args, result -> {
			Assert.fail("Unexpected result: " + result);
		}, msg -> Assert.pass(msg));
	}
}

class Main {
	static public function main() {
		var runner = new Runner();
		runner.addCase(new TestSyncInterface());
		runner.addCase(new TestAsyncInterface());
		runner.addCase(new TestAsyncError());
		var report = Report.create(runner);
		report.displayHeader = AlwaysShowHeader;
		report.displaySuccessResults = NeverShowSuccessResults;
		runner.run();
	}
}
