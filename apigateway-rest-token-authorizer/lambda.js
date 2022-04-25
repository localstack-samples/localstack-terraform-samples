exports.handler = function(event, context, callback) {
		console.log('Received event:', JSON.stringify(event, null, 2));
		var res ={
				"statusCode": 200,
				"headers": {
						"Content-Type": "application/json"
				}
		};
		res.body = "Hello, " + greeter + "!";
		callback(null, res);
};
