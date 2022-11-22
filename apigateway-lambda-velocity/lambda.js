exports.handler = function(event, context, callback) {
		console.log('Received event:', JSON.stringify(event, null, 2));
		var res ={
				"statusCode": 200,
				"headers": {
						"Content-Type": "*/*"
				}
		};
		res.body = "Hello, " + event.body.greeter + "!";
		callback(null, res);
};
