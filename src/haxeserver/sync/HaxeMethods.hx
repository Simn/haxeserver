package haxeserver.sync;

import haxeserver.protocol.Protocol;
import haxeserver.protocol.Display;
import haxeserver.protocol.Server;

abstract HaxeServerServerMethods(HaxeServerSync) from HaxeServerSync {
	public function readClassPaths() {
		return this.request(ServerMethods.ReadClassPaths).result.result;
	}

	public function configure(params:ConfigureParams) {
		return this.request(ServerMethods.Configure).result.result;
	}

	public function invalidate(params:FileParams) {
		return this.request(ServerMethods.Invalidate).result.result;
	}
}

abstract HaxeServerProtocolMethods(HaxeServerSync) from HaxeServerSync {
	public function initialize(params:InitializeParams) {
		return this.request(Methods.Initialize, params).result.result;
	}
}

abstract HaxeServerDisplayMethods(HaxeServerSync) from HaxeServerSync {
	public function completion(params:CompletionParams) {
		return this.request(DisplayMethods.Completion, params).result.result;
	}

	public function completionItemResolve(params:CompletionItemResolveParams) {
		return this.request(DisplayMethods.CompletionItemResolve, params).result.result;
	}

	public function findReferences(params:PositionParams) {
		return this.request(DisplayMethods.FindReferences, params).result.result;
	}

	public function gotoDefinition(params:PositionParams) {
		return this.request(DisplayMethods.GotoDefinition, params).result.result;
	}

	public function gotoTypeDefinition(params:PositionParams) {
		return this.request(DisplayMethods.GotoTypeDefinition, params).result.result;
	}

	public function hover(params:PositionParams) {
		return this.request(DisplayMethods.Hover, params).result.result;
	}

	public function determinePackage(params:FileParams) {
		return this.request(DisplayMethods.DeterminePackage, params).result.result;
	}

	public function signatureHelp(params:CompletionParams) {
		return this.request(DisplayMethods.SignatureHelp, params).result.result;
	}
}

/**
	Convenience API wrapper for the Haxe 4 JSON-RPC API.
**/
abstract HaxeMethods(HaxeServerSync) {
	public var display(get, never):HaxeServerDisplayMethods;
	public var protocol(get, never):HaxeServerProtocolMethods;
	public var server(get, never):HaxeServerServerMethods;

	public inline function new(haxeServer:HaxeServerSync) {
		this = haxeServer;
	}

	inline function get_display():HaxeServerDisplayMethods {
		return this;
	}

	inline function get_protocol():HaxeServerProtocolMethods {
		return this;
	}

	inline function get_server():HaxeServerServerMethods {
		return this;
	}
}
