package haxeserver.process;

import haxe.io.Bytes;

interface IHaxeServerProcess {
	function close():Void;
	function isAsynchronous():Bool;
	function request(arguments:Array<String>, ?stdin:Bytes, callback:HaxeServerRequestResult->Void):Void;
}
