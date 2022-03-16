exports.handler = function(event, context, callback) {
		console.log('Received event:', JSON.stringify(event, null, 2));
		var res ={
				"statusCode": 200,
				"headers": {
						"Content-Type": "*/*"
				}
		};
		var greeter = 'World';
		if (event.greeter && event.greeter!=="") {
				greeter =  event.greeter;
		} else if (event.body && event.body !== "") {
				var body = JSON.parse(event.body);
				if (body.greeter && body.greeter !== "") {
						greeter = body.greeter;
				}
		} else if (event.queryStringParameters && event.queryStringParameters.greeter && event.queryStringParameters.greeter !== "") {
				greeter = event.queryStringParameters.greeter;
		} else if (event.multiValueHeaders && event.multiValueHeaders.greeter && event.multiValueHeaders.greeter != "") {
				greeter = event.multiValueHeaders.greeter.join(" and ");
		} else if (event.headers && event.headers.greeter && event.headers.greeter != "") {
				greeter = event.headers.greeter;
		}

		res.body = "Hello, " + greeter + "!";
		callback(null, res);
};
