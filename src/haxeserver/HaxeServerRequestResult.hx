package haxeserver;

typedef HaxeServerRequestResult = {
	var hasError:Bool;
	var stdout:String;
	var stderr:String;
	var prints:Array<String>;
}
