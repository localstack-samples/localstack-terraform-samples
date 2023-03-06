exports.handler = function(event, context, callback) {
	console.log('Received event:', JSON.stringify(event, null, 2));
	let res = {
		"statusCode": 200,
		"headers": {
			"Content-Type": "application/json"
		},
		"body": JSON.stringify({
			"message": "Hello World!"
		})
	};
	callback(null, res);
};
