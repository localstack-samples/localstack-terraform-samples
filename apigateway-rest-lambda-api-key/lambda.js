exports.handler = function(event, context, callback) {
		console.log('Received event:', JSON.stringify(event, null, 2));

		console.log(event["headers"]["x-api-key"])
		console.log(event["body"])

		var res ={
				"statusCode": 200,
				"headers": {
						"Content-Type": "*/*"
				}
		};
		callback(null, res);
};
