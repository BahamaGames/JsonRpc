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

/*
Below are a accessible ds_priority_queue's that can be used
when using <jsonrpc_decode>. Its also recommended to manually
store the rpc locally for future use example: client request's
awaiting response.

To set a queue value set the jsonrpc key [$ "priorityQueueId"].
*/

//A struct containing all received request's id.
#macro jsonrpc_requests					global.__bg_jsonrpc_request_struct
										
//A struct containing all requests.		
#macro jsonrpc_responses				global.__bg_jsonrpc_responses

//Returned values from <jsonrpc_decode>.
/// Invalid jsonrpc						noone
#macro jsonrpc_is_request				1
#macro jsonrpc_is_notification			2
#macro jsonrpc_is_response				3
										
/// @description						Creates a jsonrpc request struct that can be used to send to a server. You may mark it as a notification by leaving id as undefined.
/// @param {String}			method		- A String containing the name of the method to be invoked.
/// @param {Any}			params		- A Structured value that holds the parameter values to be used during the invocation of the method. This member MAY be omitted.
/// @param {Any}			id			- An identifier established by the Client that MUST contain a String, Number, or NULL value if included. If it is not included it is assumed to be a notification. The value SHOULD normally not be Null [1] and Numbers SHOULD NOT contain fractional parts.
/// @return {Struct}
function jsonrpc_create_request(__bg_method, __bg_params = undefined, __bg_id = undefined)
{
	var __bg_jrpc			= {
		"jsonrpc"			: "2.0",
		"method"			: __bg_method,
	};
	
	if(__bg_params != undefined) __bg_jrpc[$ "params"] = __bg_params;
	if(__bg_id != undefined) __bg_jrpc[$ "id"] = __bg_id;
	
	return __bg_jrpc;
}

/// @description						Creates a jsonrpc result struct that can be used to send to a client.
/// @param {Any}			id			- It MUST be the same as the value of the id member in the Request Object.
/// @param {Any}			result		- The value of this member is determined by the method invoked on the Server.
/// @return {Struct}
function jsonrpc_create_result(__bg_id, __bg_result)
{
	return					{
		"id"				: __bg_id,
		"jsonrpc"			: "2.0",
		"result"			: __bg_result,
	};
}

/// @description						Creates a jsonrpc error struct that can be used to send to a client.
/// @param {Any}			id			- It MUST be the same as the value of the id member in the Request Object.
/// @param {Real}			code		- A Number that indicates the error type that occurred. This MUST be an integer.
/// @param {String}			message		- A String providing a short description of the error. The message SHOULD be limited to a concise single sentence.
/// @param {Any}			data		- A Primitive or Structured value that contains additional information about the error. This may be omitted.
/// @return {Struct}
function jsonrpc_create_error(__bg_id, __bg_code, __bg_message, __bg_data)
{
	return					{
		"id"				: __bg_id,
		"jsonrpc"			: "2.0",
		"error"				: {"code": __bg_code, "message": __bg_message, "data": __bg_data},
	};
}

/// @description						Adds a jsonrpc request object to <jsonrpc_requests>.
/// @param {Struct}			request		- JsonRpc object to add.
function jsonrpc_request_push(__bg_request)
{
	var 
	__bg_id					= __bg_request.id,
	__bg_request_			= global.__bg_jsonrpc_request_struct[$ __bg_id],
	__bg_queue;
	
	if(__bg_request_ != undefined)
	{
		__bg_queue			= global.__bg_jsonrpc_request_queue[$ __bg_request[$ "method"]];
		//Only swap if previous priority is undefined or higher than new.
		var __bg_priority	= __bg_request_[$ "priorityQueueId"];
		if(__bg_priority == undefined || __bg_priority > __bg_request[$ "priorityQueueId"]) global.__bg_jsonrpc_request_struct[$ __bg_id] = __bg_request;
	}else 
	{
		global.__bg_jsonrpc_request_struct[$ __bg_id] = __bg_request;
		
		var __bg_method		= __bg_request[$ "method"];
							
		__bg_queue			= global.__bg_jsonrpc_request_queue[$ __bg_method];
		
		if(__bg_queue == undefined) 
		{
			__bg_queue		= ds_priority_create();
			global.__bg_jsonrpc_request_queue[$ __bg_method] = __bg_queue;
		}
	}
	
	ds_priority_add(__bg_queue, __bg_request, __bg_request[$ "priorityQueueId"] ?? 0);
}

/// @description						Removes a jsonrpc request object from <jsonrpc_requests> returning it's value, or undefined if not found.
/// @param {Struct}			response	- A jsonrpc response object with targeted request id.
/// @param {Bool}			findById	- Whether to search for the request using the response.id.
/// @param {Bool}			ascending	- If findById is false search for a response using FIFO (First n First Out). 
/// @return {Any}
function jsonrpc_request_pop(__bg_response, __bg_find_by_id = true, __bg_ascending = true)
{
	var 
	__bg_id					= undefined,
	__bg_method				= undefined,
	__bg_queue				= undefined,
	__bg_request			= undefined;
							
	if(__bg_find_by_id)		
	{						
		__bg_id				= __bg_response.id;
		__bg_request		= global.__bg_jsonrpc_request_struct[$ __bg_id];
	} else {				
		__bg_method			= __bg_request[$ "method"];
		__bg_queue			= global.__bg_jsonrpc_request_queue[$ __bg_method];
		__bg_request		= __bg_ascending? ds_priority_delete_min(__bg_queue): ds_priority_delete_max(__bg_queue);
	}
		
	if(__bg_request != undefined)
	{
		__bg_id				??= __bg_response.id;
		__bg_method			??= __bg_request[$ "method"];
		__bg_queue			??= global.__bg_jsonrpc_request_queue[$ __bg_method];
		
		//Remove request from queue and struct.
		ds_priority_delete_value(__bg_queue, __bg_request);
		variable_struct_remove(global.__bg_jsonrpc_request_struct, __bg_id);
		
		//Update struct with potentially request.
		global.__bg_jsonrpc_request_struct[$ __bg_id] = ds_priority_find_min(__bg_queue);
	}
	
	return __bg_request;
}

/// @description						Adds a jsonrpc response object to <jsonrpc_responses>.
/// @param {Struct}			response	- JsonRpc object to add.
function jsonrpc_response_push(__bg_response)
{
	var 
	__bg_id					= __bg_response.id,
	__bg_response_			= global.__bg_jsonrpc_responses[$ __bg_id];
	if(__bg_response_ != undefined) delete __bg_response_;
	global.__bg_jsonrpc_responses[$ __bg_id] = __bg_response;
}

/// @description						Removes a jsonrpc response object from <jsonrpc_responses>, returning it's value, or undefined if not found.
/// @param {String}			responseId	- A JsonRpc response object id.
/// @param {Any}
function jsonrpc_response_pop(__bg_id)
{
	var __bg_response		= global.__bg_jsonrpc_responses[$ __bg_id];
	variable_struct_remove(global.__bg_jsonrpc_responses, __bg_id);
	return __bg_response;
}

/// @description						Decodes a jsonrpc message placing it within respective structs <jsonrpc_requests>, <jsonrpc_responses>. Set the jsonrpc key 
///										[$ "priorityQueueId"], to set it's priority id. You're responsible for removing jsonrpc messages's from queue's.
///										It should also be noted this function returns either constants <jsonrpc_is_request>, <jsonrpc_is_notification>, 
///										<jsonrpc_is_response>, or noone if failed. Note: notifications are not added to <jsonrpc_requests>, and should be processed
///										immediately.
/// @param {Struct}			jsonrpc		- JsonRpc struct to decode.	
/// @param {Bool}			enqueue		- Enqueue the jsonrpc in respective structs.
/// @return {Real}
function jsonrpc_decode(__bg_jsonrpc, __bg_enqueue = true)
{
	if(__bg_jsonrpc[$ "method"] != undefined) 
	{
		if(__bg_jsonrpc[$ "id"] != undefined) 
		{
			if(__bg_enqueue) jsonrpc_request_push(__bg_jsonrpc);
			return jsonrpc_is_request;
		}else return jsonrpc_is_notification;
	}else if(__bg_jsonrpc[$ "id"] != undefined && __bg_jsonrpc[$ "result"] != undefined || __bg_jsonrpc[$ "error"] != undefined) 
	{
		if(__bg_enqueue) jsonrpc_response_push(__bg_jsonrpc);
		return jsonrpc_is_response;
	}else return noone;//Invalid jsonrpc
}

/// @description						Destroys all related structs.
function jsonrpc_cleanup()
{
	for(var a = variable_struct_get_names(global.__bg_jsonrpc_request_queue), s = array_length(a), i = 0; i < s; ++i)
	{
		var q = global.__bg_jsonrpc_request_queue[$ a[i]];
		
		while(!ds_priority_empty(q)) 
		{
			var r = ds_priority_delete_min(q);
			delete r;
		}
		
		ds_priority_destroy(q);
	}
	
	delete global.__bg_jsonrpc_request_struct;
	delete global.__bg_jsonrpc_request_queue;
	delete global.__bg_jsonrpc_responses;
	
	global.__bg_jsonrpc_request_queue	= undefined;
	global.__bg_jsonrpc_request_struct	= undefined;
	global.__bg_jsonrpc_responses		= undefined;
}

global.__bg_jsonrpc_request_queue		= {};
global.__bg_jsonrpc_request_struct		= {};
global.__bg_jsonrpc_responses			= {};
