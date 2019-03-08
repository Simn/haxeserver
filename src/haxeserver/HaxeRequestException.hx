package haxeserver;

import haxeserver.protocol.Protocol;

using StringTools;

class HaxeRequestException<P, R> {
	final method:HaxeRequestMethod<P, R>;
	final params:P;
	final error:String;

	public function new(error:String, method:HaxeRequestMethod<P, R>, params:Null<P>) {
		this.error = error.trim();
		this.method = method;
		this.params = params;
	}

	public function toString() {
		return 'HaxeRequestException($error, $method, $params)';
	}
}
