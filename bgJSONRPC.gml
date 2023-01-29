/*
by		: BAHAMAGAMES / rickky
GMail	: bahamagames@gmail.com 
Discord	: rickky#1696
GitHub	: https://github.com/BahamaGames

Source	: https://www.jsonrpc.org/specification
*/

/// Feather disable all

/*
List of error codes:
	-32700				Parse error.		Invalid JSON was received by the server.
		
	An error occurred on the server while parsing the JSON text.
	
	-32600				Invalid Request.	The JSON sent is not a valid Request object.
	-32601				Method not found.	The method does not exist / is not available.
	-32602				Invalid params.		Invalid method parameter(s).
	-32603				Internal error.		Internal JSON-RPC error.
	-32000 to -32099	Server error.		Reserved for implementation-defined server-errors.
*/

//A ds_list list containing all requests.
#macro jsonrpc_requests		global.__bg_jsonrpc_requests
//A ds_list containing all results.
#macro jsonrpc_results		global.__bg_jsonrpc_results
//A ds_list containing all errors.
#macro jsonrpc_errors		global.__bg_jsonrpc_errors

//Returned values from <jsonrpc_decode>.
#macro jsonrpc_is_request	1
#macro jsonrpc_is_result	2
#macro jsonrpc_is_error		3

/// @description					Creates a jsonrpc request struct that can be used to send to a server. You may mark it as a notification by leaving id as undefined.
/// @param {String}			method	- A String containing the name of the method to be invoked.
/// @param {Any}			params	- A Structured value that holds the parameter values to be used during the invocation of the method. This member MAY be omitted.
/// @param {Any}			id		- An identifier established by the Client that MUST contain a String, Number, or NULL value if included. If it is not included it is assumed to be a notification. The value SHOULD normally not be Null [1] and Numbers SHOULD NOT contain fractional parts.
/// @return {Struct}
function jsonrpc_create_request(__bg_method, __bg_params = undefined, __bg_id = undefined)
{
	return					{
		"id"				: __bg_id,
		"jsonrpc"			: "2.0",
		"method"			: __bg_method,
		"params"			: __bg_params,
	};
}

/// @description					Creates a jsonrpc result struct that can be used to send to a client.
/// @param {Any}			id		- It MUST be the same as the value of the id member in the Request Object.
/// @param {Any}			result	- The value of this member is determined by the method invoked on the Server.
/// @return {Struct}
function jsonrpc_create_result(__bg_id, __bg_result)
{
	return					{
		"id"				: __bg_id,
		"jsonrpc"			: "2.0",
		"result"			: __bg_result,
	};
}

/// @description					Creates a jsonrpc error struct that can be used to send to a client.
/// @param {Any}			id		- It MUST be the same as the value of the id member in the Request Object.
/// @param {Real}			code	- A Number that indicates the error type that occurred. This MUST be an integer.
/// @param {String}			message	- A String providing a short description of the error. The message SHOULD be limited to a concise single sentence.
/// @param {Any}			data	- A Primitive or Structured value that contains additional information about the error. This may be omitted.
/// @return {Struct}
function jsonrpc_create_error(__bg_id, __bg_code, __bg_message, __bg_data)
{
	return					{
		"id"				: __bg_id,
		"jsonrpc"			: "2.0",
		"error"				: {"code": __bg_code, "message": __bg_message, "data": __bg_data},
	};
}

/// @description					Decodes a jsonrpc message placing it within respective ds_list <jsonrpc_requests>, <jsonrpc_results>, <jsonrpc_errors>.
///									Most recent being ds_list_size(jsonrpc_*) - 1. You're encourged to delete from list when the message is no longer needed. 
///									It should also be noted this function returns either constants <jsonrpc_is_request>, <jsonrpc_is_result>, <jsonrpc_is_error>, or 
///									noone if failed.
/// @param {Struct}			jsonrpc - JsonRpc struct to decode.	
/// @return {Real}
function jsonrpc_decode(__bg_jsonrpc)
{
	if(__bg_jsonrpc[$ "method"] != undefined) 
	{
		ds_list_add(global.__bg_jsonrpc_requests, __bg_jsonrpc);
		return jsonrpc_is_request;
	}else if(__bg_jsonrpc[$ "id"] != undefined) 
	{
		if(__bg_jsonrpc[$ "results"] != undefined) 
		{
			ds_list_add(global.__bg_jsonrpc_results, __bg_jsonrpc);
			return jsonrpc_is_result;
		}else if(__bg_jsonrpc[$ "errors"] != undefined) 
		{
			ds_list_add(global.__bg_jsonrpc_errors, __bg_jsonrpc);
			return jsonrpc_is_error
		}
		return noone;//Should never reach here!!!
	}else return noone;
}

/// @description					Destroys all related ds_lists.
function jsonrpc_cleanup()
{
	ds_list_destroy(global.__bg_jsonrpc_requests);
	ds_list_destroy(global.__bg_jsonrpc_results);
	ds_list_destroy(global.__bg_jsonrpc_errors);
	global.__bg_jsonrpc_requests	= undefined;
	global.__bg_jsonrpc_results		= undefined;
	global.__bg_jsonrpc_errors		= undefined;
}

global.__bg_jsonrpc_requests	= ds_list_create();
global.__bg_jsonrpc_results		= ds_list_create();
global.__bg_jsonrpc_errors		= ds_list_create();
