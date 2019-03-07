package haxeserver.sync;

import haxe.io.Bytes;

typedef HaxeServerRequestResult = {
	var hasError:Bool;
	var stderr:String;
	var prints:Array<String>;
}

interface IHaxeServerProcess {
	function close():Void;
	function request(arguments:Array<String>, ?stdin:Bytes):HaxeServerRequestResult;
}
