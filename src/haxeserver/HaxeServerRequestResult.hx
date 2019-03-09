package haxeserver;

import haxe.io.Bytes;

typedef HaxeServerRequestResult = {
	var hasError:Bool;
	var stdout:String;
	var stderr:String;
	var stderrRaw:Bytes;
	var prints:Array<String>;
}
