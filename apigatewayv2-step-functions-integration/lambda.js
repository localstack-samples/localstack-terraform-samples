exports.handler = function(event, context, callback) {
	console.log('Received event:', JSON.stringify(event, null, 2));
	var res ={
		"statusCode": 200,
		"body": event.body,
		"headers": {
			"Content-Type": "*/*"
		}
	};
	callback(null, res);
};
